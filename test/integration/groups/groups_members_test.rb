require 'test_helper'

class GroupsMembersTest < ActionDispatch::IntegrationTest
  def setup
    @phil  = users(:phil)
    @group = groups(:one)

    add_group_owner_to_organizers(@group)
    add_members_to_group(@group, @group.members.first)

    @member = @group.members_with_role.first
  end

  test "group owner visits group members" do
    log_in_as @phil

    visit group_members_path(@group)

    assert page.has_css? ".member-box"
  end

  test "member visits group members" do
    log_in_as @member

    visit group_members_path(@group)

    assert page.has_css? ".member-box"
  end

  test "non-member user visits members" do
    onitsuka = users(:onitsuka)

    log_in_as onitsuka

    visit group_members_path(@group)

    assert_equal current_path, root_path
  end

  test "logged out user visits members" do
    visit group_members_path(@group)

    assert_equal current_path, new_user_registration_path
  end

  test "member card shows comments number" do
    member_group_comments = @member.group_comments_number(@group)

    log_in_as @phil

    visit group_members_path(@group)

    within "#user-#{@member.id}" do
      assert page.has_content? member_group_comments
    end
  end
end