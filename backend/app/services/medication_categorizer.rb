class MedicationCategorizer
  RULES = {
    "A" => "Digestive system",
    "B" => "Blood and blood forming organs",
    "C" => "Cardiovascular system",
    "J" => "Anti-infectives",
    "N" => "Nervous system",
    "R" => "Respiratory system"
  }.freeze

  def self.call(name:, atc_code:)
    first_letter = atc_code.to_s.upcase.first
    return RULES[first_letter] if RULES.key?(first_letter)

    normalized_name = name.to_s.downcase
    return "Analgesic" if normalized_name.match?(/paracetamol|ibuprofen|morphine/)
    return "Antibiotic" if normalized_name.match?(/amoxicillin|cef|penicillin/)

    "Uncategorized"
  end
end
