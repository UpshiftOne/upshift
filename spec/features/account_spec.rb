# frozen_string_literal: true

feature 'Account' do
  scenario 'User can create an account' do
    # given I am on the sign up page
    visit '/accounts/sign_up'

    # when I enter my email address and password
    account = build(:account)
    fill_in 'Email', with: account.email
    fill_in 'Password', with: account.password
    fill_in 'Password confirmation', with: account.password
    click_on 'Sign up'

    # then I should see a success message
    expect(page).to have_text 'signed up successfully'

    # and there should be an account in the database
    expect(Account.count).to equal 1
    expect(Account).to exist(email: account.email)
  end

  scenario 'User can change password' do
    # given I am a signed-in user
    account = create(:account)
    sign_in account, scope: :account

    # when I go to the edit account page
    visit 'accounts/edit'
    # and update my password
    fill_in 'Password', with: 'newpassword'
    fill_in 'Password confirmation', with: 'newpassword'
    fill_in 'Current password', with: account.password
    click_on 'Update'

    # then I should see a success message
    expect(page).to have_text 'updated successfully'

    # and my password should be updated in the database
    expect(account.reload).to be_valid_password('newpassword')
  end

  scenario 'User can delete account' do
    # given I am a signed-in user
    account = create(:account)
    sign_in account, scope: :account

    # when I go to the edit account page
    visit 'accounts/edit'
    # and click cancel my account
    click_on 'Cancel my account'

    # then I should see a success message
    expect(page).to have_text 'successfully cancelled'

    # and my account should be deleted from the database
    expect(Account.count).to equal 0
    expect(Account).not_to exist(email: account.email)
  end
end
