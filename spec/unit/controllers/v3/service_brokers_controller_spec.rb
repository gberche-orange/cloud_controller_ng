require 'rails_helper'
require 'permissions_spec_helper'

RSpec.describe ServiceBrokersController, type: :controller do
  let(:user) { set_current_user(VCAP::CloudController::User.make, email: 'joe@example.org') }
  let(:space) { VCAP::CloudController::Space.make }
  let(:space_guid) { space.guid }
  let(:relationships_part) { {} }

  describe '#destroy' do
    let(:service_broker) { VCAP::CloudController::ServiceBroker.make }

    before do
      allow_user_global_read_access(user)
      allow_user_global_write_access(user)
      stub_delete(service_broker)
    end

    context 'when there are no service instances' do
      it 'returns a 202 and a job' do
        delete :destroy, params: { guid: service_broker.guid }
        expect(response.status).to eq 202
        expect(response['Location']).to match(%r{.*/v3/jobs/.*})
      end

      it 'updates the broker availability' do
        delete :destroy, params: { guid: service_broker.guid }
        expect(response.status).to eq 202

        get :show, params: { guid: service_broker.guid }

        expect(parsed_body).to include(
          'available' => false,
          'status' => 'delete in progress'
        )
      end
    end

    context 'when there are service instances' do
      let(:service) { VCAP::CloudController::Service.make(service_broker: service_broker) }
      let(:service_plan) { VCAP::CloudController::ServicePlan.make(service: service) }

      before do
        VCAP::CloudController::ServiceInstance.make(space: space, service_plan_id: service_plan.id)
      end

      it 'returns a 422 and do not delete the broker' do
        delete :destroy, params: { guid: service_broker.guid }
        expect(response.status).to eq 422
        expect(service_broker.exists?).to be_truthy
      end
    end

    context 'permissions' do
      context 'when the service broker does not exist' do
        it 'returns a 404' do
          delete :destroy, params: { guid: 'a-guid-that-doesnt-exist' }
          expect(response).to have_status_code(404)
          expect(response.body).to include 'Service broker not found'
        end
      end

      context 'global brokers' do
        context 'when the user has read, but not write permissions' do
          before do
            allow_user_global_read_access(user)
            disallow_user_global_write_access(user)
          end

          it 'returns a 403 Not Authorized and does NOT delete the broker' do
            delete :destroy, params: { guid: service_broker.guid }

            expect(response.status).to eq 403
            expect(response.body).to include 'NotAuthorized'
            expect(service_broker.exists?).to be_truthy
          end
        end

        context 'when the user does not have read permissions' do
          before do
            disallow_user_global_read_access(user)
          end

          it 'returns a 404 and does NOT delete the broker' do
            delete :destroy, params: { guid: service_broker.guid }

            expect(response.status).to eq 404
            expect(response.body).to include 'ResourceNotFound'
            expect(response.body).to include 'Service broker not found'
            expect(service_broker.exists?).to be_truthy
          end
        end
      end

      context 'space scoped brokers' do
        let(:service_broker) { VCAP::CloudController::ServiceBroker.make(space: space) }

        before do
          stub_delete(service_broker)
        end

        context 'when the user has read, but not write permissions on the space' do
          before do
            allow_user_read_access_for(user, spaces: [space])
            disallow_user_write_access(user, space: space)
          end

          it 'returns a 403 Not Authorized and does NOT delete the broker' do
            delete :destroy, params: { guid: service_broker.guid }

            expect(response.status).to eq 403
            expect(response.body).to include 'NotAuthorized'
            expect(service_broker.exists?).to be_truthy
          end
        end

        context 'when the user does not have read permissions on the space' do
          before do
            disallow_user_read_access(user, space: space)
          end

          it 'returns a 404 and does NOT delete the broker' do
            delete :destroy, params: { guid: service_broker.guid }

            expect(response.status).to eq 404
            expect(response.body).to include 'ResourceNotFound'
            expect(response.body).to include 'Service broker not found'
            expect(service_broker.exists?).to be_truthy
          end
        end
      end
    end
  end
end
