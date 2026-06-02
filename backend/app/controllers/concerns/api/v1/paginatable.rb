module Api
  module V1
    module Paginatable
      extend ActiveSupport::Concern

      private

      def paginate(scope, default_per_page: 10, max_per_page: 100)
        page = [ params.fetch(:page, 1).to_i, 1 ].max
        per_page = params.fetch(:per_page, default_per_page).to_i.clamp(1, max_per_page)
        total_count = scope.count
        records = scope.offset((page - 1) * per_page).limit(per_page)

        [
          records,
          {
            page:,
            per_page:,
            total_count:,
            total_pages: (total_count.to_f / per_page).ceil
          }
        ]
      end

      def filter_created_at_range(scope)
        scope = scope.where(created_at: Time.zone.parse(params[:from])..) if params[:from].present?
        scope = scope.where(created_at: ..Time.zone.parse(params[:to]).end_of_day) if params[:to].present?
        scope
      end
    end
  end
end
