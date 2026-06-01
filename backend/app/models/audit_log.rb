class AuditLog < ApplicationRecord
  validates :actor, :role, :action, :auditable_type, presence: true
end
