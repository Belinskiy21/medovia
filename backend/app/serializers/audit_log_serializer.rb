class AuditLogSerializer
  def self.render(log)
    {
      id: log.id,
      actor: log.actor,
      role: log.role,
      action: log.action,
      auditable_type: log.auditable_type,
      auditable_id: log.auditable_id,
      metadata: log.metadata,
      created_at: log.created_at
    }
  end
end
