require_relative './helper/spec_helper'

describe Routific do
  let(:base_api_url) { 'https://api.routific.com' }
  let(:endpoints)    { %w(vrp vrp-long pdp pdp-long) }
  let(:visits) { {
    'order_1' => {
      'start'    => '9:00',
      'end'      => '12:00',
      'duration' => 10,
      'location' => {
        'name' => '6800 Cambie',
        'lat'  => 49.227107,
        'lng'  => -123.1163085
      }
    }
  } }
  let(:fleet) { {
    'vehicle_1' => {
      'start_location' => {
        'name' => '800 Kingsway',
        'lat'  => 49.2553636,
        'lng'  => -123.0873365
      },
      'end_location' => {
        'name' => '800 Kingsway',
        'lat'  => 49.2553636,
        'lng'  => -123.0873365
      },
      'shift_start' => '8:00',
      'shift_end'   => '12:00'
    }
  } }
  let(:route_data) { {
    visits: visits,
    fleet:  fleet
  } }

  shared_examples_for 'making a valid request' do
    it 'makes a request with the correct params' do
      expect(RestClient::Request).to receive(:execute) do |args|
        expect(args).to include(timeout: 20,
                                headers: including(content_type:  :json,
                                                   accept:        :json)
        )
        response_hash.to_json
      end
      request
    end
  end

  describe 'initializing' do
    before do
      Routific.setToken 'foo'
    end

    context 'without a token' do
      subject { Routific.new }

      it 'uses the class token by default' do
        expect(subject.token).to eq('foo')
      end
    end

    context 'with a token' do
      subject { Routific.new('bar') }

      it 'uses that token' do
        expect(subject.token).to eq('bar')
      end
    end
  end

  describe "instance methods" do
    subject(:routific) { Routific.new(ENV['API_KEY']) }

    describe '#endpoint' do
      it 'returns the default endpoint' do
        expect(routific.endpoint).to eq(:vrp)
      end
    end

    describe '#endpoint=' do
      around do |example|
        old_endpoint = routific.endpoint
        example.run
        routific.endpoint = old_endpoint
      end

      it 'changes the endpoint if a valid endpoint is given' do
        endpoints.each do |endpoint|
          routific.endpoint = endpoint
          expect(routific.endpoint).to eq(endpoint)
        end
      end

      it 'raises an error if an invalid endpoint is given' do
        expect { routific.endpoint = 'invalid' }.to raise_error(Routific::InvalidEndpoint)
      end
    end

    describe "#visits" do
      it "is instance of a Hash" do
        expect(routific.visits).to be_instance_of(Hash)
      end
    end

    describe "#fleet" do
      it "is instance of a Hash" do
        expect(routific.fleet).to be_instance_of(Hash)
      end
    end

    describe "#setVisit" do
      let(:id) { Faker::Lorem.word }
      before do
        routific.setVisit(id, Factory::VISIT_PARAMS)
      end

      it "adds location 1 into visits" do
        expect(routific.visits).to include(id)
      end

      it "location 1 in visits is instances of Visit" do
        expect(routific.visits[id]).to be_instance_of(RoutificApi::Visit)
      end
    end

    describe "#setVehicle" do
      let(:id) { Faker::Lorem.word }

      before do
        routific.setVehicle(id, Factory::VEHICLE_PARAMS)
      end

      it "adds vehicle into fleet" do
        expect(routific.fleet).to include(id)
      end

      it "vehicle in fleet is instances of Vehicle" do
        expect(routific.fleet[id]).to be_instance_of(RoutificApi::Vehicle)
      end
    end

    describe "#getRoute" do
      describe 'vehicle routing endpoints' do
        before do
          visits.each do |id, params|
            routific.setVisit(id, params)
          end

          fleet.each do |id, params|
            routific.setVehicle(id, params)
          end
        end

        describe 'vrp' do
          before do
            routific.endpoint = 'vrp'
          end

          it "returns a Route instance" do
            route = routific.getRoute()
            expect(route).to be_instance_of(RoutificApi::Route)
          end
        end

        describe 'vrp-long' do
          before do
            routific.endpoint = 'vrp-long'
          end

          it 'returns a Job instance with an ID' do
            route = routific.getRoute()
            expect(route).to be_instance_of(RoutificApi::Job)
            expect(route.id).to_not be_nil
          end
        end
      end

      describe 'pickup and delivery endpoints' do
        describe 'pdp'
        describe 'pdp-long'
      end
    end
  end

  describe "class methods" do
    describe '.endpoint' do
      it 'returns the default endpoint' do
        expect(Routific.endpoint).to eq(:vrp)
      end
    end

    describe '.endpoint=' do
      around do |example|
        old_endpoint = Routific.endpoint
        example.run
        Routific.endpoint = old_endpoint
      end

      it 'changes the endpoint if a valid endpoint is given' do
        endpoints.each do |endpoint|
          Routific.endpoint = endpoint
          expect(Routific.endpoint).to eq(endpoint)
        end
      end

      it 'raises an error if an invalid endpoint is given' do
        expect { Routific.endpoint = 'invalid' }.to raise_error(Routific::InvalidEndpoint)
      end

      it 'changes the endpoint for all new instances' do
        endpoints.each do |endpoint|
          Routific.endpoint = endpoint
          expect(Routific.new(ENV["API_KEY"]).endpoint).to eq(endpoint)
        end
      end
    end

    describe ".setToken" do
      before do
        Routific.setToken(ENV["API_KEY"])
      end

      it "sets default Routific API token" do
        expect(Routific.token).to eq(ENV["API_KEY"])
      end
    end

    describe ".getRoute" do
      it_behaves_like 'making a valid request' do
        let(:request)       { Routific.getRoute(route_data) }
        let(:response_hash) { Factory::ROUTE_API_RESPONSE }
      end

      describe "access token is nil" do
        it "throws an ArgumentError" do
          expect { Routific.getRoute({}, nil) }.to raise_error(ArgumentError)
        end
      end

      describe "valid access token" do
        describe "access token is set" do
          before do
            Routific.setToken(ENV["API_KEY"])
          end

          it "returns a Route instance" do
            expect(Routific.getRoute(route_data)).to be_instance_of(RoutificApi::Route)
          end

          describe 'formatting timestamps' do
            # Change the "start" and "end" values to
            # Time objects for this test.
            let(:visits) { {
              'order_1' => {
                'start'    => Time.parse('9:00'),
                'end'      => Time.parse('12:00'),
                'duration' => 10,
                'location' => {
                  'name' => '6800 Cambie',
                  'lat'  => 49.227107,
                  'lng'  => -123.1163085
                }
              }
            } }

            it 'converts Time objects into strings like "8:15"' do
              expect(RestClient::Request).to receive(:execute) do |args|
                data = JSON.parse(args[:payload])
                # Check that the Time objects have been converted
                # to strings in the correct format.
                expect(data['visits']['order_1']['start']).to eq('9:00')
                expect(data['visits']['order_1']['end']).to eq('12:00')
                # Check that the other params are still the same
                %w(duration location).each do |param|
                  expect(data['visits']['order_1'][param]).to eq(visits['order_1'][param])
                end
                Factory::JOB_API_RESPONSE['output'].to_json
              end
              Routific.getRoute(route_data)
            end
          end
        end

        describe "access token is provided" do
          before do
            Routific.setToken(nil)
          end

          it "returns a Route instance" do
            expect(Routific.getRoute(route_data, ENV["API_KEY"])).to be_instance_of(RoutificApi::Route)
          end

          it "still successful even if missing prefix 'bearer ' in key" do
            key = ENV["API_KEY"].sub /bearer /, ''
            expect(/bearer /.match(key).nil?).to be true
            expect(Routific.getRoute(route_data, key)).to be_instance_of(RoutificApi::Route)
          end
        end
      end
    end

    describe '.job' do
      let(:job_id)  { 'ii5w2kb5846' }
      let(:api_url) { "#{base_api_url}/jobs/#{job_id}" }

      context 'without access token' do
        it 'raises an ArgumentError' do
          expect { Routific.job(job_id, nil) }.to raise_error(ArgumentError)
        end
      end

      context 'with an access token' do
        before do
          Routific.setToken(ENV["API_KEY"])
        end

        it_behaves_like 'making a valid request' do
          let(:request)       { Routific.job(job_id) }
          let(:response_hash) { Factory::JOB_API_RESPONSE }
        end

        it 'calls RoutificApi::Route.parse with the correct JSON' do
          stub_request(:get, api_url).to_return(body: Factory::JOB_API_RESPONSE.to_json)
          expect(RoutificApi::Job).to receive(:parse).with(Factory::JOB_API_RESPONSE)
          Routific.job(job_id)
        end
      end
    end
  end
end
