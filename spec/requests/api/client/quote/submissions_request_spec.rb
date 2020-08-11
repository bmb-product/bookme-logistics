require 'rails_helper'

RSpec.describe "API::Client::Quote::Submissions", type: :request do
  let!(:exp) { 2.day.from_now.to_i}
  let!(:payload) do
    {
      "iss": "bmb-starter-logistic.github.com",
      "aud": "ssr-client",
      "sub": "api",
      "name": "Quote app",
      "role": "dynamic",
      "exp": exp
    }
  end

  let!(:token) { JwtGenerator.encode(payload)}

  describe "GET /index" do
    it "renders a successful response" do
      submission = create(:quote_submission)
      create(:quote_contact, submission: submission)
      create(:quote_delivery_address, submission: submission)
      create(:quote_pickup_address, submission: submission)

      get api_client_quote_submissions_url, headers: headers_jwt_bearer_token
      json = json_response

      expect(json.length).to eq 1
      expect(json[0]['id']).to eq submission.id
    end
  end

  describe "GET /show" do
    it "renders a successful response" do
       
      quote_submission = create(:quote_submission)
      quote_contact = create(:quote_contact, submission: quote_submission)
      quote_pickup_address = create(:quote_pickup_address, submission: quote_submission)
      quote_delivery_address = create(:quote_delivery_address, submission: quote_submission)
      quote_shipment_item = create(:quote_shipment_item, submission: quote_submission)

      get api_client_quote_submission_url(quote_submission, locale: :en), headers: headers_jwt_bearer_token
      json = json_response

      expect(json['id']).to be quote_submission.id
      expect(json['shipment_items_count']).to be 1
      expect(json['contact']['id']).to be quote_contact.id
      expect(json['pickup_address']['id']).to be quote_pickup_address.id
      expect(json['delivery_address']['id']).to be quote_delivery_address.id
      expect(json['shipment_items'][0]['id']).to be quote_shipment_item.id
    end
  end

  describe "GET /new" do
    it "renders a successful response" do
      get new_api_client_quote_submission_url, headers: headers_jwt_bearer_token
      json = json_response

      attrs = {
        "pickup_address_attributes"=>["id", "name", "lat", "lon"],
        "delivery_address_attributes"=>["id", "name", "lat", "lon"],
        "contact_attributes"=>["id", "name", "email", "phone_number", "title"],
        "shipment_items_attributes"=>["id", "width", "length", "height", "weight", "weight_unit", "dimension_unit", "number_of_item"]
      }
      expect(json).to match attrs
    end
  end

  describe "POST /create" do
    let(:attrs) do
      {
        pickup_address_attributes: {
          name: "Wat Phnom, ផ្លូវវត្តភ្នំ, រាជធានី​ភ្នំពេញ",
          lat: "11.5659647",
          lon: "104.9150842",
        },

        delivery_address_attributes: {
          name: "Banlung, ក្រុងបានលុង, Ratanakiri",
          lat: "13.7375463",
          lon: "106.9775092"
        },

        shipment_items_attributes: [{
          width: 40,
          length: 20,
          height: 35,
          dimension_unit: 'cm',

          weight: 30,
          weight_unit: 'kg'
        },
        
        {
          width: 10,
          length: 20,
          height: 20,
          dimension_unit: 'cm',

          weight: 30,
          weight_unit: 'kg'
        }
      ],

        contact_attributes: {
          name: 'Joean',
          email: 'joeann@gmail.com',
          phone_number: '0972223334',
          title: 'mrs.',

        }
      }
    end

    context "with valid parameters" do
      it "creates a new Quote::Submission" do
        post api_client_quote_submissions_url(locale: :en), params: { quote_submission: attrs }, headers: headers_jwt_bearer_token
        json = json_response
        
        expect(json['id'].present?).to be true
        expect(json['shipment_items_count']).to be 2
        expect(json['contact']['id'].present?).to be true
        expect(json['pickup_address']['id'].present?).to be true
        expect(json['delivery_address']['id'].present?).to be true
        expect(json['shipment_items'].length).to be 2

      end
    end

    context "with invalid parameters" do
      it "does not create a new Quote::Submission" do
        attrs[:contact_attributes][:name] = nil
        attrs[:delivery_address_attributes][:lat] = nil
        attrs[:shipment_items_attributes][0][:width] = nil
        attrs[:shipment_items_attributes][1][:length] = nil

        post api_client_quote_submissions_url(locale: :en), params: { quote_submission: attrs }, headers: headers_jwt_bearer_token

        json = json_response
        result = {
          "error" => {
            "contact"=>{"name"=>["can't be blank"]}, 
            "delivery_address"=>{"lat"=>["can't be blank"]},
            "shipment_items"=>{
              "0"=>{"width"=>["can't be blank"]}, 
              "1"=>{"length"=>["can't be blank"]}
            }
          }
        }

        expect(json).to match result
      end
    end
  end

  describe "PATCH /update" do
    let(:submission) { create(:quote_submission)}
    let(:delivery_address) { create(:quote_delivery_address, submission: submission)}
    let(:pickup_address) { create(:quote_pickup_address, submission: submission)}
    let(:contact) { create(:quote_contact, submission: submission)}
    let(:shipment_item) { create(:quote_shipment_item, submission: submission)}

    let(:update_attrs) do
      {
        pickup_address_attributes: {
          id: pickup_address.id,
          name: "Wat Phnom",
          lat: "11",
          lon: "101",
        },

        delivery_address_attributes: {
          id: delivery_address.id,
          name: "Banlung",
          lat: "15",
          lon: "105"
        },

        shipment_items_attributes: [{
          id: shipment_item.id,
          width: 20,
          length: 30,
          height: 40,
          dimension_unit: 'm',

          weight: 60,
          weight_unit: 'lbs',
          number_of_item: 1,
        }],

        contact_attributes: {
          id: contact.id,
          name: 'Jhone',
          email: 'jhone@gmail.com',
          phone_number: '012987654',
          title: 'mr.',
        }
      }
    end


    context "with valid parameters" do

      it "updates the requested quote_submission" do
        patch api_client_quote_submission_url(submission, locale: :en), params: { quote_submission: update_attrs }, headers: headers_jwt_bearer_token
        submission.reload

        expect(submission.pickup_address.name).to eq 'Wat Phnom'
        expect(submission.pickup_address.lat).to eq 11
        expect(submission.pickup_address.lon).to eq 101

        expect(submission.delivery_address.name).to eq 'Banlung'
        expect(submission.delivery_address.lat).to eq 15
        expect(submission.delivery_address.lon).to eq 105

        shipment = submission.shipment_items.first
        expect(shipment.width).to eq 20
        expect(shipment.length).to eq 30
        expect(shipment.height).to eq 40
        expect(shipment.weight).to eq 60
        
        expect(submission.contact.name).to eq 'Jhone'
        expect(submission.contact.email).to eq 'jhone@gmail.com'
        expect(submission.contact.phone_number).to eq '012987654'
        expect(submission.contact.title).to eq 'mr.'
      end
    end

    context "with invalid parameters" do
      it "renders a successful response (i.e. to display the 'edit' template)" do
        update_attrs[:contact_attributes][:name] = nil

        patch api_client_quote_submission_url(submission, locale: :en), params: { quote_submission: update_attrs }, headers: headers_jwt_bearer_token
       
        json = json_response
        expect(json).to eq({"contact"=>{"name"=>["can't be blank"]}})
      end
    end
  end

  describe "DELETE /destroy" do
    it "destroys the requested quote_submission" do
      quote_submission = create(:quote_submission)
      count = Quote::Submission.count

      delete api_client_quote_submission_url(quote_submission, locale: :en), headers: headers_jwt_bearer_token
      
      expect(Quote::Submission.count).to eq (count - 1)
      expect(response.status).to eq 200
    end

    it "redirects to the quote_submissions list" do
      quote_submission = create(:quote_submission)

      delete quote_submission_url(quote_submission, locale: :en)
      expect(response).to redirect_to(quote_submissions_url(locale: :en))
    end
  end
end

