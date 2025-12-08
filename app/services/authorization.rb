class Authorization
  PERMISSIONS = {
    admin: {
      users: [:index, :show, :create, :edit, :delete, :change_status, :manage_family_members, :manage_mentees],
      events: [:index, :show, :create, :edit, :delete],
      teams: [:index, :show, :create, :edit, :delete, :manage_members],
      navigation: [:dashboard, :users, :events, :teams, :event_types, :olympic_seasons]
    },
    staff: {
      users: [:index, :show, :create, :edit, :manage_family_members, :manage_mentees],
      events: [:index, :show, :create, :edit, :delete],
      teams: [:index, :show, :create, :edit, :delete, :manage_members],
      navigation: [:dashboard, :users, :events, :teams, :event_types, :olympic_seasons]
    },
    mentor: {
      users: [],
      events: [:index, :show],
      teams: [:index, :show],
      mentees: [:index, :show, :create, :destroy],
      navigation: [:dashboard, :mentees, :events, :teams]
    },
    guardian: {
      users: [],
      events: [:index, :show],
      navigation: [:dashboard, :events]
    },
    mentee: {
      users: [],
      events: [:index, :show],
      navigation: [:dashboard, :events]
    },
    volunteer: {
      users: [],
      events: [:index, :show],
      navigation: [:dashboard, :events]
    }
  }.freeze

  # Actions that cannot be performed on yourself
  SELF_RESTRICTED = [:delete, :change_status].freeze

  def initialize(user)
    @user = user
    @role = determine_role(user)
  end

  def can?(action, resource, target = nil)
    return false unless @role

    permissions = PERMISSIONS.dig(@role, resource)
    return false unless permissions&.include?(action)

    # Check self-restriction
    if SELF_RESTRICTED.include?(action) && target == @user
      return false
    end

    true
  end

  def navigation
    return [] unless @role
    PERMISSIONS.dig(@role, :navigation) || []
  end

  def can_access?(nav_item)
    navigation.include?(nav_item)
  end

  def role
    @role
  end

  # Class methods for convenience
  class << self
    def can?(user, action, resource, target = nil)
      new(user).can?(action, resource, target)
    end

    def navigation_for(user)
      new(user).navigation
    end

    def can_access?(user, nav_item)
      new(user).can_access?(nav_item)
    end
  end

  private

  def determine_role(user)
    return nil unless user

    if user.staff&.admin?
      :admin
    elsif user.staff.present?
      :staff
    elsif user.mentor.present?
      :mentor
    elsif user.guardian.present?
      :guardian
    elsif user.mentee.present?
      :mentee
    elsif user.volunteer.present?
      :volunteer
    end
  end
end
