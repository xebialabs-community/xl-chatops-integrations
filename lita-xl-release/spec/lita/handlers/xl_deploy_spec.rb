require "spec_helper"
require 'multi_json'
require 'cobravsmongoose'

describe Lita::Handlers::XlDeploy, lita_handler: true do

	it { is_expected.to route("deployments") }
	it { is_expected.to route("deploy") }
	it { is_expected.to route("deploy petclinic") }
	it { is_expected.to route("deploy petclinic 1.0") }
	it { is_expected.to route("deploy petclinic 1.0 to dev") }
	it { is_expected.to route("deploy petclinic to dev") }
	it { is_expected.to route("deploy to dev") }

	it { is_expected.to route("start") }
	it { is_expected.to route("start ac4df") }

	it { is_expected.to route("cancel") }
	it { is_expected.to route("cancel ac4df") }

	it { is_expected.to route("archive") }
	it { is_expected.to route("archive ac4df") }

	it { is_expected.to route("abort") }
	it { is_expected.to route("abort ac4df") }

	it { is_expected.to route("desc") }
	it { is_expected.to route("desc ac4df") }

	describe "tasks" do

		XLD_TASKS_REST_JSON = '{"list":{"task":{"@id":"6f065290-fafa-4fc4-9aab-3dd14f3e935d","@currentStep":"1","@totalSteps":"4","@failures":"1","@state":"STOPPED","@state2":"FAILED","@owner":"admin","description":{"$":"Initial deployment of Environments/TEST/PetClinic-war"},"startDate":{"$":"2016-03-10T20:49:59.105+0000"},"completionDate":{"$":"2016-03-10T20:49:59.123+0000"},"currentSteps":{"current":{"$":"1"}},"metadata":{"environment":{"$":"TEST"},"taskType":{"$":"INITIAL"},"environment_id":{"$":"Environments/TEST"},"application":{"$":"PetClinic-war"},"version":{"$":"1.0"}}}}}'
		XLD_NO_DEPLOYMENT_EXISTS_JSON = '{ "boolean": {"$": "false"} }'
		XLD_FIND_APPLICATION_SINGLE_RESULT_JSON = '{"list": {"ci": {"@ref": "Applications/PetClinic-war", "@type": "udm.Application"}}}'
		XLD_FIND_VERSION_SINGLE_RESULT_JSON = '{"list": {"ci": {"@ref": "Applications/PetClinic-war/1.0", "@type": "udm.DeploymentPackage"}}}'
		XLD_FIND_ENVIRONMENT_SINGLE_RESULT_JSON = '{"list": {"ci": {"@ref": "Environments/DEV", "@type": "udm.Environment"}}}'
		XLD_PREPARE_DEPLOYMENT_RESULT_XML = 
'<deployment id="deployment-7a21a7e6-4ca5-4b52-b004-436aa890beb0" type="INITIAL">
  <application>
    <udm.DeployedApplication id="Environments/DEV/PetClinic-war">
      <version ref="Applications/PetClinic-war/1.0"/>
      <environment ref="Environments/DEV"/>
      <deployeds/>
      <orchestrator/>
      <optimizePlan>true</optimizePlan>
    </udm.DeployedApplication>
  </application>
  <deployeds/>
  <deployables>
    <ci ref="Applications/PetClinic-war/1.0/petclinic" type="jee.War"/>
  </deployables>
  <containers>
    <ci ref="Infrastructure/localhost/tomcat-server/Petclinic" type="tomcat.VirtualHost"/>
  </containers>
  <requiredDeployments/>
</deployment>'

		XLD_PREPARE_DEPLOYEDS_RESULT_XML = 
'<deployment id="deployment-7a21a7e6-4ca5-4b52-b004-436aa890beb0" type="INITIAL">
  <application>
    <udm.DeployedApplication id="Environments/DEV/PetClinic-war">
      <version ref="Applications/PetClinic-war/1.0"/>
      <environment ref="Environments/DEV"/>
      <deployeds/>
      <orchestrator/>
      <optimizePlan>true</optimizePlan>
    </udm.DeployedApplication>
  </application>
  <deployeds>
    <tomcat.WarModule id="Infrastructure/localhost/tomcat-server/Petclinic/petclinic">
      <deployable ref="Applications/PetClinic-war/1.0/petclinic"/>
      <container ref="Infrastructure/localhost/tomcat-server/Petclinic"/>
      <placeholders/>
      <contextRoot>${deployed.name}</contextRoot>
    </tomcat.WarModule>
  </deployeds>
  <deployables>
    <ci ref="Applications/PetClinic-war/1.0/petclinic" type="jee.War"/>
  </deployables>
  <containers>
    <ci ref="Infrastructure/localhost/tomcat-server/Petclinic" type="tomcat.VirtualHost"/>
  </containers>
  <requiredDeployments/>
</deployment>'

		it "can list deployments" do
			restApi = instance_double("XldRestApi", "XLD REST API")
			allow(restApi).to receive(:do_get_tasks).and_return(MultiJson.load(XLD_TASKS_REST_JSON))
			allow(subject).to receive(:xld_rest_api).at_least(:once).and_return(restApi)

			response = double("response")
			expect(response).to receive(:reply).with("List of deployments:")
			expect(response).to receive(:reply).with(/\[STOPPED\] PetClinic-war\/1\.0 to TEST/)
			
			message = double("message")
			expect(response).to receive(:message).at_least(:once).and_return(message)
			user = double("user")
			expect(message).to receive(:user).at_least(:once).and_return(user)
			expect(user).to receive(:id).at_least(:once).and_return("1")

			room = double("room")
			expect(message).to receive(:room_object).at_least(:once).and_return(room)
			expect(room).to receive(:id).at_least(:once).and_return("1")

			subject.list_deployments(response)
		end

	end

	it "can start a deployment" do
		restApi = instance_double("XldRestApi", "XLD REST API")
		allow(subject).to receive(:xld_rest_api).at_least(:once).and_return(restApi)
		allow(restApi).to receive(:find_application).with(any_args).and_return(MultiJson.load(XLD_FIND_APPLICATION_SINGLE_RESULT_JSON))
		allow(restApi).to receive(:find_version).with(any_args).and_return(MultiJson.load(XLD_FIND_VERSION_SINGLE_RESULT_JSON))
		allow(restApi).to receive(:find_environment).with(any_args).and_return(MultiJson.load(XLD_FIND_ENVIRONMENT_SINGLE_RESULT_JSON))
		allow(restApi).to receive(:deployment_exists).with(any_args).and_return(MultiJson.load(XLD_NO_DEPLOYMENT_EXISTS_JSON))
		allow(restApi).to receive(:prepare_deployment).with(any_args).and_return(MultiJson.load(CobraVsMongoose.xml_to_json(XLD_PREPARE_DEPLOYMENT_RESULT_XML)))
		allow(restApi).to receive(:prepare_deployeds).with(any_args).and_return(MultiJson.load(CobraVsMongoose.xml_to_json(XLD_PREPARE_DEPLOYEDS_RESULT_XML)))
		allow(restApi).to receive(:create_deployment).with(any_args).and_return("7aebd120-d0b7-43ce-817b-2121c56a5ed2")
		allow(restApi).to receive(:start_task).with(any_args)

		response = double("response")
		matchdata = double("matchdata")
		message = double("message")
		expect(response).to receive(:message).at_least(:once).and_return(message)
		expect(response).to receive(:match_data).at_least(:once).and_return([ "", "", "petclinic", "", "1.0", "", "test"])

		user = double("user")
		expect(message).to receive(:user).at_least(:once).and_return(user)
		expect(user).to receive(:id).at_least(:once).and_return("1")

		room = double("room")
		expect(message).to receive(:room_object).at_least(:once).and_return(room)
		expect(room).to receive(:id).at_least(:once).and_return("1")

		expect(response).to receive(:reply).with(/Starting deployment of PetClinic-war-1.0 to DEV/)

		subject.start_deployment(response)
	end

end
