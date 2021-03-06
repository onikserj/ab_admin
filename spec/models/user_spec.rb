require 'spec_helper'

describe User do

  describe 'associations' do
    it { should have_one(:avatar) }
  end

  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should_not allow_value('blah').for(:email) }
    it { should allow_value('a@b.com').for(:email) }
    it { should_not allow_value('123').for(:password) }
    it { should allow_value('123456').for(:password) }
    it { should_not allow_value(5).for(:user_role_id) }
  end

  describe 'attributes' do
    it 'allow mass assignment of user data attributes' do
      [:password, :password_confirmation, :email, :remember_me,
       :login, :first_name, :last_name, :patronymic, :phone, :skype, :web_site, :address, :birthday,
       :time_zone, :locale, :bg_color].each do |attr|
        should allow_mass_assignment_of(attr)
      end
    end
    it 'allow mass assignment of user_role_id, trust_state only for admin' do
      should_not allow_mass_assignment_of(:user_role_id)
      should allow_mass_assignment_of(:user_role_id).as(:admin)
    end
  end

  describe 'scopes' do
    before :all do
      @user = create(:default_user)
      @moderator = create(:moderator_user)
      @inactive = create(:user)
    end

    it 'search for managers' do
      expect(User.managers).not_to include(@user)
      User.managers.should include(@moderator)
    end

    it 'search for active users' do
      User.active.should include(@user)
      expect(User.managers).not_to include(@inactive)
    end
  end

  context 'after create' do
    before :all do
      @user = create(:default_user)
      @admin = create(:admin_user)
      @moderator = create(:moderator_user)
      @inactive = create(:user, email: 'test@example.com')
    end

    before :each do
      @user.reload
      @admin.reload
      @moderator.reload
      @inactive.reload
    end

    it '#title' do
      expect(@inactive.name).to eq @inactive.email
      expect(@user.name).to eq @user.full_name
    end

    it '#full_name' do
      expect(@user.full_name).to eq "#{@user.first_name} #{@user.last_name}"
    end

    it 'set user defaults' do
      expect(@inactive.user_role_id).to eq ::UserRoleType.default.id
      expect(@inactive.locale).to eq 'ru'
      expect(@inactive.time_zone).to eq 'Kiev'
    end

    it 'generate login' do
      expect(@inactive.login).to eq 'test'
    end

    describe 'auth' do
      it '#generate_password!' do
        new_pass = @user.generate_password!
        expect(@user.valid_password?(new_pass)).to be_truthy
      end

      it 'activate user' do
        @inactive.activate!
        expect(@inactive.locked_at).to be_nil
      end

      it 'activate! user' do
        @inactive.activate!
        @inactive.reload
        expect(@inactive.locked_at).to be_nil
        expect(@inactive).to be_confirmed
      end

      it 'should set default role' do
        @inactive.reload
        @inactive.user_role_id = nil
        @inactive.save
        expect(@inactive.user_role_id).to eq ::UserRoleType.default.id
      end

      it 'active for authentication' do
        expect(@user).to be_active_for_authentication
      end

      it 'suspend user' do
        @user.suspend!
        expect(@user.locked_at).not_to be_blank
      end

      describe 'roles' do
        it 'default' do
          expect(@user).to be_default
        end

        it 'moderator' do
          expect(@moderator).to be_moderator
          expect(@admin).to be_moderator
        end

        it 'admin' do
          expect(@admin).to be_admin
        end
      end
    end
  end
end
