module Api
  module V1
    class MedicationsController < BaseController
      before_action :set_unit, only: [:index, :create]

      def index
        medications = @unit.medications.search(params[:q]).by_form(params[:form]).order(:name)
        render json: medications.map { |medication| MedicationSerializer.render(medication) }
      end

      def show
        render json: MedicationSerializer.render(Medication.find(params[:id]))
      end

      def create
        return unless role_allowed?("pharmacist", "admin")

        medication = @unit.medications.create!(medication_params)
        audit!("medication.created", medication, medication: medication.slice(:name, :atc_code, :form, :strength))
        render json: MedicationSerializer.render(medication), status: :created
      end

      def update
        return unless role_allowed?("pharmacist", "admin")

        medication = Medication.find(params[:id])
        medication.update!(medication_params)
        audit!("medication.updated", medication, medication: medication.slice(:name, :atc_code, :form, :strength, :inventory_balance))
        render json: MedicationSerializer.render(medication)
      end

      def destroy
        return unless role_allowed?("admin")

        medication = Medication.find(params[:id])
        medication.destroy!
        audit!("medication.deleted", medication, medication: medication.slice(:name, :atc_code))
        head :no_content
      end

      private

      def set_unit
        @unit = HealthcareUnit.find(params[:healthcare_unit_id])
      end

      def medication_params
        params.require(:medication).permit(:name, :atc_code, :form, :strength, :inventory_balance, :minimum_threshold)
      end
    end
  end
end
