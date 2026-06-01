module Api
  module V1
    class HealthcareUnitsController < BaseController
      def index
        render json: HealthcareUnit.order(:name).map { |unit| HealthcareUnitSerializer.render(unit) }
      end

      def show
        render json: HealthcareUnitSerializer.render(HealthcareUnit.find(params[:id]))
      end
    end
  end
end
