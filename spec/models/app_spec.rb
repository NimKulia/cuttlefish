# frozen_string_literal: true

require "spec_helper"

describe App do
  describe "#smtp_password" do
    it "should create a password that is twenty characters long" do
      expect(FactoryBot.create(:app).smtp_password.size).to eq 20
    end

    it "should create a password that is different every time" do
      expect(FactoryBot.create(:app).smtp_password).to_not eq FactoryBot.create(:app).smtp_password
    end
  end

  describe "#name" do
    it "should allow upper and lower case letters, numbers, spaces and underscores" do
      expect(FactoryBot.build(:app, name: "Foo12 Bar_Foo")).to be_valid
    end

    it "should not allow other characters" do
      expect(FactoryBot.build(:app, name: "*")).to_not be_valid
    end
  end

  describe "#smtp_username" do
    it "should set the smtp_username based on the name when created" do
      app = FactoryBot.create(:app, name: "Planning Alerts", id: 15)
      expect(app.smtp_username).to eq "planning_alerts_15"
    end

    it "should not change the smtp_username if the name is updated" do
      app = FactoryBot.create(:app, name: "Planning Alerts", id: 15)
      app.update_attributes(name: "Another description")
      expect(app.smtp_username).to eq "planning_alerts_15"
    end
  end

  describe "#custom_tracking_domain" do
    it "should look up the cname of the custom domain and check it points to the cuttlefish server" do
      app = FactoryBot.build(:app, custom_tracking_domain: "email.myapp.com")
      expect(App).to receive(:lookup_dns_cname_record).with("email.myapp.com").and_return("localhost.")
      expect(app).to be_valid
    end

    it "should look up the cname of the custom domain and check it points to the cuttlefish server" do
      app = FactoryBot.build(:app, custom_tracking_domain: "email.foo.com")
      expect(App).to receive(:lookup_dns_cname_record).with("email.foo.com").and_return("foo.com.")
      expect(app).to_not be_valid
    end

    it "should not look up the cname if the custom domain hasn't been set" do
      app = FactoryBot.build(:app)
      expect(App).to_not receive(:lookup_dns_cname_record)
      expect(app).to be_valid
    end
  end

  describe "#dkim_private_key" do
    it "should be generated automatically" do
      app = FactoryBot.create(:app)
      expect(app.dkim_private_key.to_pem.split("\n").first).to eq "-----BEGIN RSA PRIVATE KEY-----"
    end

    it "should be different for different apps" do
      app1 = FactoryBot.create(:app)
      app2 = FactoryBot.create(:app)
      expect(app1.dkim_private_key).to_not eq app2.dkim_private_key
    end

    it "should be saved in the database" do
      app = FactoryBot.create(:app)
      value = app.dkim_private_key.to_pem
      app.reload
      expect(app.dkim_private_key.to_pem).to eq value
    end
  end

  describe "#dkim_selector" do
    let(:app) { FactoryBot.create(:app, name: "Book store", id: 15) }

    it "should include the name and the id to be unique" do
      expect(app.dkim_selector).to eq "book_store_15.cuttlefish"
    end

    context "legacy dkim selector" do
      let(:app) { FactoryBot.create(:app, legacy_dkim_selector: true) }
      it "should just be cuttlefish" do
        expect(app.dkim_selector).to eq "cuttlefish"
      end
    end
  end

  describe ".cuttlefish" do
    before(:each) { allow(Rails.configuration).to receive(:cuttlefish_domain).and_return("cuttlefish.io") }
    let(:app) { App.cuttlefish }

    it { expect(app.name).to eq "Cuttlefish" }
    it { expect(app.from_domain).to eq "cuttlefish.io" }
    it { expect(app.team).to be_nil }

    it "should return the same instance when request twice" do
      expect(app.id).to eq App.cuttlefish.id
    end
  end

  describe "#open_tracking_enabled" do
    it "should not validate with nil value" do
      app = FactoryBot.build(:app, open_tracking_enabled: nil)
      expect(app).to_not be_valid
    end
  end

  # The following two tests are commented out because they require a network connection and
  # are testing real things in DNS so in general it makes the tests fragile. Though, if you're
  # working on the lookup_dns_cname_record method it's probably a good idea to uncomment them!

  # describe "#lookup_dns_cname_record" do
  #   it "should resolve the cname of www.openaustralia.org" do
  #     expect(App.lookup_dns_cname_record("www.openaustralia.org")).to eq "kedumba.openaustralia.org."
  #   end
  #
  #   it "should not resolve the cname of twiddlesticks.openaustralia.org" do
  #    expect(App.lookup_dns_cname_record("twiddlesticks.openaustralia.org")).to be_nil
  #   end
  # end
end
