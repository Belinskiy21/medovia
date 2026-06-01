class AddDomainUniquenessIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :healthcare_units,
      "lower(name), lower(location)",
      unique: true,
      name: "index_healthcare_units_on_lower_name_location"

    add_index :medications,
      "healthcare_unit_id, lower(atc_code), lower(form), lower(strength)",
      unique: true,
      name: "index_medications_on_unit_atc_form_strength"

    add_index :order_lines,
      [:order_id, :medication_id],
      unique: true,
      name: "index_order_lines_on_order_medication"
  end
end
