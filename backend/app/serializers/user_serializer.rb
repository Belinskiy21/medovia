class UserSerializer
  def self.render(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      memberships: user.memberships.includes(:healthcare_unit).map do |membership|
        {
          healthcare_unit_id: membership.healthcare_unit_id,
          healthcare_unit_name: membership.healthcare_unit.name,
          role: membership.role
        }
      end
    }
  end
end
