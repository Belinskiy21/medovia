module Api
  module V1
    class HealthcareUnitsController < BaseController
      def index
        units = if current_principal.kind == "service"
          HealthcareUnit.order(:name)
        else
          current_principal.record.healthcare_units.distinct.order(:name)
        end

        render json: units.map { |unit| HealthcareUnitSerializer.render(unit) }
      end

      def show
        unit = HealthcareUnit.find(params[:id])
        return unless unit_access_allowed?(unit)

        render json: HealthcareUnitSerializer.render(unit)
      end
    end
  end
end
