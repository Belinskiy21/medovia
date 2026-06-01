class HealthcareUnitSerializer
  def self.render(unit)
    {
      id: unit.id,
      name: unit.name,
      location: unit.location
    }
  end
end
