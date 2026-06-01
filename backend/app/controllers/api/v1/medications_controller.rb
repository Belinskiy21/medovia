module Api
  module V1
    class MedicationsController < BaseController
      before_action :set_unit, only: [ :index, :create ]

      def index
        return unless unit_access_allowed?(@unit)

        medications = @unit.medications.search(params[:q]).by_form(params[:form]).order(:name)
        medications = medications.where("inventory_balance < minimum_threshold") if params[:low_stock].to_s == "true"
        total_count = medications.count
        page = page_param
        per_page = per_page_param
        paginated_medications = medications.offset((page - 1) * per_page).limit(per_page)

        render json: {
          data: paginated_medications.map { |medication| MedicationSerializer.render(medication) },
          meta: {
            page:,
            per_page:,
            total_count:,
            total_pages: (total_count.to_f / per_page).ceil
          }
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

      def page_param
        [params.fetch(:page, 1).to_i, 1].max
      end

      def per_page_param
        params.fetch(:per_page, 10).to_i.clamp(1, 1000)
      end
    end
  end
end
