# frozen_string_literal: true

require "rails_helper"
require "ordering_api/add_sombo"

describe OrderingApi::AddSombo, backend: true do
  it "creates SOMBO OMS and adds SOMBO admin to it" do
    described_class.new.call

    expect(User.count).to eq(1)
    expect(User.first.first_name).to eq("SOMBO admin")
    expect(User.first.roles_mask).to eq(7)
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "doesn't create SOMBO OMS and SOMBO admin if they exist" do
    admin =
      create(
        :user,
        first_name: "SOMBO admin",
        last_name: "SOMBO admin",
        email: "sombo@sombo.com",
        roles_mask: 1
      )
    admin.reload.primary_identity.update!(uid: "iamasomboadmin")
    create(:oms, name: "SOMBO", administrators: [admin])

    described_class.new.call

    expect(User.count).to eq(1)
    expect(admin.reload.first_name).to eq("SOMBO admin")
    expect(admin.roles_mask).to eq(7)
    expect(OMS.count).to eq(1)
    expect(OMS.first.name).to eq("SOMBO")
    expect(OMS.first.administrators.first.first_name).to eq("SOMBO admin")
  end

  it "creates SOMBO OMS, SOMBO admin relationship if they exist" do
    sombo_admin = create(
      :user, 
      first_name: "SOMBO admin", 
      last_name: "SOMBO admin", 
      email: "sombo@sombo.com"
    )
    
    sombo_admin.reload.primary_identity.update!(uid: "iamasomboadmin")
    create(:oms, name: "SOMBO")

    described_class.new.call

    expect(OMS.count).to eq(1)
    OMS.all.each do |sombo|
      expect(sombo.administrators.count).to eq(3)
      expect(sombo.administrators).to include(sombo_admin)
    end
  end

  it "creates SOMBO OMS, SOMBO admin relationship if SOMBO exists and admin doesn't" do
    create(:oms, name: "SOMBO")

    described_class.new.call

    expect(OMS.count).to eq(1)
    OMS.all.each do |sombo|
      expect(sombo.administrators.count).to eq(3)
      expect(sombo.administrators).to include(UserIdentity.find_by(provider: "checkin", uid: "iamasomboadmin").user)
    end
  end
end
