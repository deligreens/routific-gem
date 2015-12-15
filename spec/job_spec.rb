require_relative './helper/spec_helper'

describe RoutificApi::Job do
  describe '.parse' do
    context 'with valid JSON' do
      let(:json)     { Factory::JOB_API_RESPONSE }
      let(:solution) { json['output']['solution'] }

      it 'initializes a new job object' do
        job = described_class.parse(json)

        expect(job.status).to eq('finished')
        expect(job.raw).to    eq(json)

        route = job.route
        expect(route).to          be_instance_of(RoutificApi::Route)
        expect(route.fitness).to  be_nil
        expect(route.unserved).to be_nil

        routes = route.vehicleRoutes
        expect(routes).to      be_instance_of(Hash)
        expect(routes.keys).to match_array(solution.keys)

        routes.each do |vehicle, waypoints|
          expect(waypoints.size).to eq(solution[vehicle].size)
          waypoints.each do |waypoint|
            expect(waypoint).to be_instance_of(RoutificApi::WayPoint)
            waypoint_json = solution[vehicle].detect do |_waypoint_json|
              _waypoint_json['location_id'] == waypoint.location_id
            end
            expect(waypoint.location_id).to  eq(waypoint_json['location_id'])
            expect(waypoint.arrival_time).to eq(waypoint_json['arrival_time'])
            expect(waypoint.finish_time).to  eq(waypoint_json['finish_time'])
          end
        end
      end
    end
  end
end
