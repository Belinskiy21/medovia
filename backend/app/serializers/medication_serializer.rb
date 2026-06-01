class MedicationSerializer
  def self.render(medication)
    {
      id: medication.id,
      healthcare_unit_id: medication.healthcare_unit_id,
      name: medication.name,
      atc_code: medication.atc_code,
      form: medication.form,
      strength: medication.strength,
      inventory_balance: medication.inventory_balance,
      minimum_threshold: medication.minimum_threshold,
      category: medication.category,
      low_inventory: medication.low_inventory?
    }
  end
end
