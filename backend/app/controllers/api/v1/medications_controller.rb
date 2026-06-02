module Api
  module V1
    class MedicationsController < BaseController
      before_action :set_unit, only: [ :index, :create ]

      def index
        return unless unit_access_allowed?(@unit)

        medications = @unit.medications.search(params[:q]).by_form(params[:form]).order(:name)
        medications = medications.where("inventory_balance < minimum_threshold") if params[:low_stock].to_s == "true"
        paginated_medications, meta = paginate(medications, max_per_page: 1000)

        render json: {
          data: paginated_medications.map { |medication| MedicationSerializer.render(medication) },
          meta:
        }
      end

      def show
        medication = Medication.find(params[:id])
        return unless unit_access_allowed?(medication.healthcare_unit)

        render json: MedicationSerializer.render(medication)
      end

      def create
        return unless role_allowed?("pharmacist", "admin", healthcare_unit: @unit)

        medication = @unit.medications.create!(medication_params)
        audit!("medication.created", medication, medication: medication.slice(:name, :atc_code, :form, :strength))
        render json: MedicationSerializer.render(medication), status: :created
      end

      def update
        medication = Medication.find(params[:id])
        return unless role_allowed?("pharmacist", "admin", healthcare_unit: medication.healthcare_unit)

        medication.update!(medication_params)
        audit!("medication.updated", medication, medication: medication.slice(:name, :atc_code, :form, :strength, :inventory_balance))
        render json: MedicationSerializer.render(medication)
      end

      def destroy
        medication = Medication.find(params[:id])
        return unless role_allowed?("admin", healthcare_unit: medication.healthcare_unit)

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
