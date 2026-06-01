module Api
  module V1
    class SessionsController < BaseController
      skip_before_action :authenticate_request!, only: :create

      def create
        user = User.find_by(email: session_params[:email].to_s.downcase)

        if user&.authenticate(session_params[:password])
          render json: {
            token: AuthToken.issue(user),
            user: UserSerializer.render(user)
          }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      private

      def session_params
        params.require(:session).permit(:email, :password)
      end
    end
  end
end
