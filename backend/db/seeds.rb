cardiology = HealthcareUnit.find_or_create_by!(name: "Karolinska Cardiology", location: "Stockholm")
emergency = HealthcareUnit.find_or_create_by!(name: "Sahlgrenska Emergency", location: "Gothenburg")

[
  ["nurse@medovia.test", "Lina Nurse", "nurse", "NursePass123!"],
  ["pharmacist@medovia.test", "Erik Pharmacist", "pharmacist", "PharmacistPass123!"],
  ["admin@medovia.test", "Amina Admin", "admin", "AdminPass123!"]
].each do |email, name, role, password|
  user = User.find_or_initialize_by(email:)
  user.update!(name:, role:, password:, password_confirmation: password)
end

[
  [cardiology, "Metoprolol", "C07AB02", "tablet", "50 mg", 18, 20],
  [cardiology, "Furosemide", "C03CA01", "injection solution", "10 mg/ml", 8, 12],
  [cardiology, "Warfarin", "B01AA03", "tablet", "2.5 mg", 40, 15],
  [emergency, "Paracetamol", "N02BE01", "tablet", "500 mg", 120, 40],
  [emergency, "Morphine", "N02AA01", "injection solution", "10 mg/ml", 7, 10],
  [emergency, "Amoxicillin", "J01CA04", "capsule", "500 mg", 25, 20]
].each do |unit, name, atc_code, form, strength, balance, threshold|
  unit.medications.find_or_create_by!(atc_code:, name:) do |medication|
    medication.form = form
    medication.strength = strength
    medication.inventory_balance = balance
    medication.minimum_threshold = threshold
  end
end

unless cardiology.orders.exists?
  cardiology.orders.create!(
    created_by: "lina.nurse@medovia.test",
    order_lines_attributes: [
      { medication: cardiology.medications.find_by!(name: "Metoprolol"), quantity: 30 },
      { medication: cardiology.medications.find_by!(name: "Furosemide"), quantity: 20 }
    ]
  )
end
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
