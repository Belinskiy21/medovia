import React, { useEffect, useMemo, useState } from "react";
import { createRoot } from "react-dom/client";
import { AlertTriangle, ClipboardList, Clock3, Download, Eye, LogOut, PackagePlus, Pencil, Plus, RefreshCw, Search, Send, Trash2 } from "lucide-react";
import { ErrorBoundary } from "./ErrorBoundary";
import "./styles.css";

const API_BASE = import.meta.env.VITE_API_BASE_URL ?? "http://localhost:3001/api/v1";
const roleOptions = ["nurse", "pharmacist", "admin"] as const;
const medicationForms = ["tablet", "capsule", "injection solution", "oral solution", "inhalation", "cream"];
const sessionStorageKey = "meditrack.session";
const demoAccounts = [
  { role: "nurse", email: "nurse@medovia.test", password: "NursePass123!" },
  { role: "pharmacist", email: "pharmacist@medovia.test", password: "PharmacistPass123!" },
  { role: "admin", email: "admin@medovia.test", password: "AdminPass123!" }
] as const;

type Role = (typeof roleOptions)[number];
type HealthcareUnit = { id: number; name: string; location: string };
type Medication = {
  id: number;
  healthcare_unit_id: number;
  name: string;
  atc_code: string;
  form: string;
  strength: string;
  inventory_balance: number;
  minimum_threshold: number;
  category: string;
  low_inventory: boolean;
};
type OrderLine = { id: number; medication_id: number; medication_name: string; atc_code: string; quantity: number };
type Order = {
  id: number;
  status: "draft" | "sent" | "confirmed" | "delivered";
  created_by: string;
  created_at: string;
  sent_at: string | null;
  confirmed_at: string | null;
  delivered_at: string | null;
  order_lines: OrderLine[];
};
type AuditLog = { id: number; actor: string; role: string; action: string; created_at: string; metadata: Record<string, unknown> };
type SessionUser = { id: number; email: string; name: string; role: Role };
type Session = { token: string; user: SessionUser };
type MedicationFormState = Omit<Medication, "id" | "healthcare_unit_id" | "category" | "low_inventory">;

const emptyMedication: MedicationFormState = {
  name: "",
  atc_code: "",
  form: "tablet",
  strength: "",
  inventory_balance: 0,
  minimum_threshold: 10
};

function storedSession(): Session | null {
  const value = window.localStorage.getItem(sessionStorageKey);
  if (!value) return null;

  try {
    return JSON.parse(value) as Session;
  } catch {
    window.localStorage.removeItem(sessionStorageKey);
    return null;
  }
}

function App() {
  const [session, setSession] = useState<Session | null>(() => storedSession());
  const [loginEmail, setLoginEmail] = useState<string>(demoAccounts[1].email);
  const [loginPassword, setLoginPassword] = useState<string>(demoAccounts[1].password);
  const [units, setUnits] = useState<HealthcareUnit[]>([]);
  const [unitId, setUnitId] = useState<number | null>(null);
  const [medications, setMedications] = useState<Medication[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLog[]>([]);
  const [query, setQuery] = useState("");
  const [formFilter, setFormFilter] = useState("");
  const [orderQuery, setOrderQuery] = useState("");
  const [orderFormFilter, setOrderFormFilter] = useState("");
  const [medicationForm, setMedicationForm] = useState<MedicationFormState>(emptyMedication);
  const [editingId, setEditingId] = useState<number | null>(null);
  const [orderLines, setOrderLines] = useState<Record<number, number>>({});
  const [selectedOrderId, setSelectedOrderId] = useState<number | null>(null);
  const [activeView, setActiveView] = useState<"workspace" | "low-stock">("workspace");
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const selectedUnit = units.find((unit) => unit.id === unitId);
  const lowStock = medications.filter((medication) => medication.low_inventory);
  const orderMedicationOptions = medications.filter((medication) => {
    const matchesQuery = [medication.name, medication.atc_code, medication.form].some((value) => value.toLowerCase().includes(orderQuery.toLowerCase()));
    const matchesForm = !orderFormFilter || medication.form === orderFormFilter;
    return matchesQuery && matchesForm;
  });
  const role = session?.user.role ?? "nurse";

  const headers = useMemo(
    () => ({
      "Content-Type": "application/json",
      ...(session ? { Authorization: `Bearer ${session.token}` } : {})
    }),
    [session]
  );

  async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
    const response = await fetch(`${API_BASE}${path}`, {
      ...options,
      headers: { ...headers, ...(options.headers ?? {}) }
    });
    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      throw new Error(body.error ?? body.errors?.join(", ") ?? "Request failed");
    }
    if (response.status === 204) return undefined as T;
    return response.json();
  }

  async function login(event: React.FormEvent) {
    event.preventDefault();
    setLoading(true);
    setError("");
    try {
      const response = await fetch(`${API_BASE}/session`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ session: { email: loginEmail, password: loginPassword } })
      });
      if (!response.ok) {
        const body = await response.json().catch(() => ({}));
        throw new Error(body.error ?? "Login failed");
      }
      const nextSession = (await response.json()) as Session;
      window.localStorage.setItem(sessionStorageKey, JSON.stringify(nextSession));
      setSession(nextSession);
      setUnits([]);
      setUnitId(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Login failed");
    } finally {
      setLoading(false);
    }
  }

  function logout() {
    window.localStorage.removeItem(sessionStorageKey);
    setSession(null);
    setUnits([]);
    setUnitId(null);
    setMedications([]);
    setOrders([]);
    setAuditLogs([]);
    setSelectedOrderId(null);
    setActiveView("workspace");
  }

  async function refresh(nextUnitId = unitId) {
    if (!nextUnitId) return;
    setLoading(true);
    setError("");
    try {
      const [nextMedications, nextOrders] = await Promise.all([
        request<Medication[]>(`/healthcare_units/${nextUnitId}/medications?q=${encodeURIComponent(query)}&form=${encodeURIComponent(formFilter)}`),
        request<Order[]>(`/healthcare_units/${nextUnitId}/orders`)
      ]);
      setMedications(nextMedications);
      setOrders(nextOrders);
      if (role === "admin") {
        setAuditLogs(await request<AuditLog[]>("/audit_logs"));
      } else {
        setAuditLogs([]);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to load data");
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!session) {
      setLoading(false);
      return;
    }

    request<HealthcareUnit[]>("/healthcare_units")
      .then((nextUnits) => {
        setUnits(nextUnits);
        setUnitId(nextUnits[0]?.id ?? null);
        return refresh(nextUnits[0]?.id);
      })
      .catch((err) => {
        setError(err instanceof Error ? err.message : "Unable to load units");
        setLoading(false);
      });
  }, [session]);

  useEffect(() => {
    if (!session) return;

    refresh();
  }, [unitId, query, formFilter, session]);

  function editMedication(medication: Medication) {
    setEditingId(medication.id);
    setMedicationForm({
      name: medication.name,
      atc_code: medication.atc_code,
      form: medication.form,
      strength: medication.strength,
      inventory_balance: medication.inventory_balance,
      minimum_threshold: medication.minimum_threshold
    });
  }

  async function submitMedication(event: React.FormEvent) {
    event.preventDefault();
    if (!unitId) return;
    setError("");
    try {
      if (editingId) {
        await request<Medication>(`/medications/${editingId}`, {
          method: "PATCH",
          body: JSON.stringify({ medication: medicationForm })
        });
      } else {
        await request<Medication>(`/healthcare_units/${unitId}/medications`, {
          method: "POST",
          body: JSON.stringify({ medication: medicationForm })
        });
      }
      setMedicationForm(emptyMedication);
      setEditingId(null);
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to save medication");
    }
  }

  async function deleteMedication(id: number) {
    setError("");
    try {
      await request<void>(`/medications/${id}`, { method: "DELETE" });
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to delete medication");
    }
  }

  async function createOrder() {
    if (!unitId) return;
    const lines = (Object.entries(orderLines) as [string, number][])
      .filter(([, quantity]) => quantity > 0)
      .map(([medicationId, quantity]) => ({ medication_id: Number(medicationId), quantity }));
    if (lines.length === 0) {
      setError("Add at least one medication quantity before creating an order.");
      return;
    }
    setError("");
    try {
      await request<Order>(`/healthcare_units/${unitId}/orders`, {
        method: "POST",
        body: JSON.stringify({ order: { order_lines_attributes: lines } })
      });
      setOrderLines({});
      setSelectedOrderId(null);
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to create order");
    }
  }

  async function advanceOrder(orderId: number) {
    setError("");
    try {
      await request<Order>(`/orders/${orderId}/advance`, { method: "PATCH" });
      await refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to advance order");
    }
  }

  async function exportOrders() {
    if (!unitId) return;
    setError("");
    try {
      const response = await fetch(`${API_BASE}/healthcare_units/${unitId}/orders_export`, { headers });
      if (!response.ok) throw new Error("Unable to export orders");

      const blob = await response.blob();
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = `meditrack-orders-unit-${unitId}.csv`;
      link.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unable to export orders");
    }
  }

  function exportLowStock() {
    const rows = [
      ["Name", "ATC code", "Form", "Strength", "Current balance", "Minimum threshold", "Deficit", "Category"],
      ...lowStock.map((medication) => [
        medication.name,
        medication.atc_code,
        medication.form,
        medication.strength,
        medication.inventory_balance,
        medication.minimum_threshold,
        medication.minimum_threshold - medication.inventory_balance,
        medication.category
      ])
    ];
    const csv = rows.map((row) => row.map((value) => `"${String(value).replace(/"/g, "\"\"")}"`).join(",")).join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `meditrack-low-stock-unit-${unitId}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  }

  if (!session) {
    return (
      <main>
        <section className="login-panel">
          <div>
            <h1>MediTrack</h1>
            <p>Sign in with a seeded demo account.</p>
          </div>
          {error && <div className="notice error">{error}</div>}
          <form className="stack" onSubmit={login}>
            <select
              value={loginEmail}
              onChange={(event) => {
                const account = demoAccounts.find((item) => item.email === event.target.value);
                if (!account) return;
                setLoginEmail(account.email);
                setLoginPassword(account.password);
              }}
              aria-label="Demo account"
            >
              {demoAccounts.map((account) => (
                <option key={account.email} value={account.email}>
                  {account.role} · {account.email}
                </option>
              ))}
            </select>
            <input value={loginEmail} onChange={(event) => setLoginEmail(event.target.value)} placeholder="Email" />
            <input type="password" value={loginPassword} onChange={(event) => setLoginPassword(event.target.value)} placeholder="Password" />
            <button className="primary" type="submit" disabled={loading}>
              Sign in
            </button>
          </form>
        </section>
      </main>
    );
  }

  return (
    <main>
      <header className="topbar">
        <div>
          <h1>MediTrack</h1>
          <p>{selectedUnit ? `${selectedUnit.name}, ${selectedUnit.location}` : "Loading healthcare unit"}</p>
        </div>
        <div className="topbar-actions">
          <select value={unitId ?? ""} onChange={(event) => setUnitId(Number(event.target.value))} aria-label="Healthcare unit">
            {units.map((unit) => (
              <option key={unit.id} value={unit.id}>
                {unit.name}
              </option>
            ))}
          </select>
          <span className="user-chip">{session.user.name} · {session.user.role}</span>
          <button className="icon-button" onClick={() => refresh()} aria-label="Refresh">
            <RefreshCw size={18} />
          </button>
          <button className="icon-button" onClick={logout} aria-label="Sign out">
            <LogOut size={18} />
          </button>
        </div>
      </header>

      {error && <div className="notice error">{error}</div>}
      {loading && <div className="notice">Loading current inventory and orders...</div>}

      <section className="summary-grid">
        <Summary label="Medications" value={medications.length} />
        <Summary label="Open orders" value={orders.filter((order) => order.status !== "delivered").length} />
        <Summary label="Low stock" value={lowStock.length} urgent={lowStock.length > 0} />
      </section>

      {lowStock.length > 0 && (
        <section className="warning-band">
          <AlertTriangle size={18} />
          <span>{lowStock.length} medications are below their minimum threshold.</span>
          <button className="secondary" onClick={() => setActiveView("low-stock")}>
            Review list
          </button>
        </section>
      )}

      <section className="view-tabs" aria-label="Primary view">
        <button className={activeView === "workspace" ? "tab active" : "tab"} onClick={() => setActiveView("workspace")}>
          Registry and orders
        </button>
        <button className={activeView === "low-stock" ? "tab active" : "tab"} onClick={() => setActiveView("low-stock")}>
          Low stock
        </button>
      </section>

      {activeView === "low-stock" ? (
        <section className="panel">
          <div className="panel-heading">
            <h2>Low stock medications</h2>
            <button className="secondary" onClick={exportLowStock} disabled={lowStock.length === 0}>
              <Download size={18} /> CSV
            </button>
          </div>
          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>ATC</th>
                  <th>Form</th>
                  <th>Strength</th>
                  <th>Balance</th>
                  <th>Deficit</th>
                  <th>Category</th>
                </tr>
              </thead>
              <tbody>
                {lowStock.map((medication) => (
                  <tr key={medication.id} className="low">
                    <td>{medication.name}</td>
                    <td>{medication.atc_code}</td>
                    <td>{medication.form}</td>
                    <td>{medication.strength}</td>
                    <td>
                      {medication.inventory_balance} / {medication.minimum_threshold}
                    </td>
                    <td>{medication.minimum_threshold - medication.inventory_balance}</td>
                    <td>{medication.category}</td>
                  </tr>
                ))}
              </tbody>
            </table>
            {lowStock.length === 0 && <p className="empty-state">No medications are below threshold.</p>}
          </div>
        </section>
      ) : (
        <>

      <div className="workspace">
        <section className="panel medication-panel">
          <div className="panel-heading">
            <h2>Medication registry</h2>
            <div className="filters">
              <label>
                <Search size={16} />
                <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Name, ATC, form" />
              </label>
              <select value={formFilter} onChange={(event) => setFormFilter(event.target.value)} aria-label="Filter by form">
                <option value="">All forms</option>
                {medicationForms.map((form) => (
                  <option key={form} value={form}>
                    {form}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="table-wrap">
            <table>
              <thead>
                <tr>
                  <th>Name</th>
                  <th>ATC</th>
                  <th>Form</th>
                  <th>Strength</th>
                  <th>Balance</th>
                  <th>Category</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {medications.map((medication) => (
                  <tr key={medication.id} className={medication.low_inventory ? "low" : ""}>
                    <td>{medication.name}</td>
                    <td>{medication.atc_code}</td>
                    <td>{medication.form}</td>
                    <td>{medication.strength}</td>
                    <td>
                      {medication.inventory_balance} / {medication.minimum_threshold}
                    </td>
                    <td>{medication.category}</td>
                    <td className="row-actions">
                      <button className="icon-button" onClick={() => editMedication(medication)} aria-label={`Edit ${medication.name}`}>
                        <Pencil size={16} />
                      </button>
                      <button className="icon-button danger" onClick={() => deleteMedication(medication.id)} aria-label={`Delete ${medication.name}`}>
                        <Trash2 size={16} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        <aside className="panel">
          <h2>{editingId ? "Edit medication" : "Add medication"}</h2>
          <form className="stack" onSubmit={submitMedication}>
            <input required value={medicationForm.name} onChange={(event) => setMedicationForm({ ...medicationForm, name: event.target.value })} placeholder="Name" />
            <input required value={medicationForm.atc_code} onChange={(event) => setMedicationForm({ ...medicationForm, atc_code: event.target.value.toUpperCase() })} placeholder="ATC code" />
            <select value={medicationForm.form} onChange={(event) => setMedicationForm({ ...medicationForm, form: event.target.value })}>
              {medicationForms.map((form) => (
                <option key={form} value={form}>
                  {form}
                </option>
              ))}
            </select>
            <input required value={medicationForm.strength} onChange={(event) => setMedicationForm({ ...medicationForm, strength: event.target.value })} placeholder="Strength" />
            <div className="split">
              <input type="number" min="0" value={medicationForm.inventory_balance} onChange={(event) => setMedicationForm({ ...medicationForm, inventory_balance: Number(event.target.value) })} aria-label="Inventory balance" />
              <input type="number" min="0" value={medicationForm.minimum_threshold} onChange={(event) => setMedicationForm({ ...medicationForm, minimum_threshold: Number(event.target.value) })} aria-label="Minimum threshold" />
            </div>
            <button className="primary" type="submit">
              <PackagePlus size={18} /> {editingId ? "Update" : "Add"}
            </button>
          </form>
        </aside>
      </div>

      <section className="orders-grid">
        <div className="panel">
          <div className="panel-heading">
            <h2>Create order</h2>
            <button className="primary" onClick={createOrder}>
              <Plus size={18} /> Create draft
            </button>
          </div>
          <div className="filters order-filters">
            <label>
              <Search size={16} />
              <input value={orderQuery} onChange={(event) => setOrderQuery(event.target.value)} placeholder="Name, ATC, form" />
            </label>
            <select value={orderFormFilter} onChange={(event) => setOrderFormFilter(event.target.value)} aria-label="Filter order medications by form">
              <option value="">All forms</option>
              {medicationForms.map((form) => (
                <option key={form} value={form}>
                  {form}
                </option>
              ))}
            </select>
          </div>
          <div className="order-lines">
            {orderMedicationOptions.map((medication) => (
              <label key={medication.id} className="order-line">
                <span>
                  {medication.name}
                  <small>{medication.atc_code} · current {medication.inventory_balance}</small>
                </span>
                <input type="number" min="0" value={orderLines[medication.id] ?? 0} onChange={(event) => setOrderLines({ ...orderLines, [medication.id]: Number(event.target.value) })} />
              </label>
            ))}
            {orderMedicationOptions.length === 0 && <p className="empty-state">No medications match this order filter.</p>}
          </div>
        </div>

        <div className="panel">
          <div className="panel-heading">
            <h2>Order history</h2>
            <button className="secondary" onClick={exportOrders}>
              <Download size={18} /> CSV
            </button>
          </div>
          <div className="order-history">
            {orders.map((order) => (
              <article key={order.id} className="order-card">
                <div className="order-head">
                  <strong>Order #{order.id}</strong>
                  <Status status={order.status} />
                </div>
                <p>{new Date(order.created_at).toLocaleString()} by {order.created_by}</p>
                <ul>
                  {order.order_lines.map((line) => (
                    <li key={line.id}>
                      {line.medication_name} · {line.atc_code} · {line.quantity}
                    </li>
                  ))}
                </ul>
                <div className="order-actions">
                  <button className="secondary" onClick={() => setSelectedOrderId(selectedOrderId === order.id ? null : order.id)}>
                    <Eye size={16} /> {selectedOrderId === order.id ? "Hide details" : "Details"}
                  </button>
                  {order.status !== "delivered" && (
                    <button className="secondary" onClick={() => advanceOrder(order.id)}>
                      <Send size={16} /> Advance
                    </button>
                  )}
                </div>
                {selectedOrderId === order.id && <OrderDetails order={order} />}
              </article>
            ))}
          </div>
        </div>
      </section>

      {role === "admin" && (
        <section className="panel">
          <h2>Audit log</h2>
          <div className="audit-list">
            {auditLogs.map((log) => (
              <div key={log.id}>
                <ClipboardList size={16} />
                <span>{log.action}</span>
                <small>{log.actor} · {new Date(log.created_at).toLocaleString()}</small>
              </div>
            ))}
          </div>
        </section>
      )}
        </>
      )}
    </main>
  );
}

function Summary({ label, value, urgent = false }: { label: string; value: number; urgent?: boolean }) {
  return (
    <div className={`summary ${urgent ? "urgent" : ""}`}>
      <span>{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function Status({ status }: { status: Order["status"] }) {
  return <span className={`status ${status}`}>{status}</span>;
}

function OrderDetails({ order }: { order: Order }) {
  const events = [
    { label: "Created", value: order.created_at, actor: order.created_by },
    { label: "Sent", value: order.sent_at },
    { label: "Confirmed", value: order.confirmed_at },
    { label: "Delivered", value: order.delivered_at }
  ];

  return (
    <div className="order-details">
      <div className="status-timeline">
        {events.map((event) => (
          <div key={event.label} className={event.value ? "timeline-event complete" : "timeline-event"}>
            <Clock3 size={16} />
            <span>{event.label}</span>
            <small>{event.value ? `${new Date(event.value).toLocaleString()}${event.actor ? ` by ${event.actor}` : ""}` : "Not yet"}</small>
          </div>
        ))}
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(
  <ErrorBoundary>
    <App />
  </ErrorBoundary>
);
