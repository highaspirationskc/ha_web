class Authorization
  PERMISSIONS = {
    admin: {
      users: [:index, :show, :create, :edit, :delete, :change_status, :manage_family_members, :manage_mentees, :manage_event_logs],
      events: [:index, :show, :create, :edit, :delete],
      teams: [:index, :show, :create, :edit, :delete, :manage_members],
      messages: [:index, :show, :create, :support_inbox],
      media: [:index, :show, :create, :delete, :manage_all],
      navigation: [:dashboard, :users, :events, :teams, :event_types, :olympic_seasons, :inbox, :media]
    },
    staff: {
      users: [:index, :show, :create, :edit, :manage_family_members, :manage_mentees, :manage_event_logs],
      events: [:index, :show, :create, :edit, :delete],
      teams: [:index, :show, :create, :edit, :delete, :manage_members],
      messages: [:index, :show, :create, :support_inbox],
      media: [:index, :show, :create, :delete, :manage_all],
      navigation: [:dashboard, :users, :events, :teams, :event_types, :olympic_seasons, :inbox, :media]
    },
    mentor: {
      users: [],
      events: [:index, :show],
      teams: [:index, :show],
      mentees: [:index, :show, :create, :destroy],
      messages: [:index, :show, :create],
      media: [:index, :show, :create, :delete],
      navigation: [:dashboard, :mentees, :events, :teams, :inbox]
    },
    guardian: {
      users: [],
      events: [:index, :show],
      messages: [:index, :show, :create],
      media: [:index, :show, :create, :delete],
      navigation: [:dashboard, :events, :inbox]
    },
    mentee: {
      users: [],
      events: [:index, :show],
      messages: [:index, :show, :create],
      media: [:index, :show, :create, :delete],
      navigation: [:dashboard, :events, :inbox]
    },
    volunteer: {
      users: [],
      events: [:index, :show],
      messages: [:index, :show, :create],
      media: [:index, :show, :create, :delete],
      navigation: [:dashboard, :events, :inbox]
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

  # Check if user can message a specific recipient
  # If in_thread_with is provided, allows replying to anyone in that thread
  def can_message?(recipient, in_thread_with: nil)
    return false unless @user
    return false if recipient == @user

    # Allow replying to anyone who is in the same message thread
    if in_thread_with.present?
      thread_user_ids = thread_participant_ids(in_thread_with)
      return true if thread_user_ids.include?(recipient.id)
    end

    case @role
    when :admin, :staff
      # Can message anyone
      true
    when :mentor
      # Can message their mentees, their mentees' guardians, or support
      mentee_ids = @user.mentor&.mentees&.pluck(:id) || []
      mentee_user_ids = Mentee.where(id: mentee_ids).joins(:user).pluck("users.id")

      # Get guardians of mentees
      guardian_user_ids = FamilyMember.joins(:mentee, guardian: :user)
                                       .where(mentee_id: mentee_ids)
                                       .pluck("users.id")

      (mentee_user_ids + guardian_user_ids).include?(recipient.id)
    when :mentee
      # Can message their mentor, their guardians, or support
      mentor_user_id = @user.mentee&.mentor&.user&.id
      guardian_user_ids = @user.mentee&.family_members&.joins(guardian: :user)&.pluck("users.id") || []

      ([mentor_user_id] + guardian_user_ids).compact.include?(recipient.id)
    when :guardian
      # Can message their mentees, their mentees' mentor, or support
      mentee_ids = @user.guardian&.family_members&.pluck(:mentee_id) || []
      mentee_user_ids = Mentee.where(id: mentee_ids).joins(:user).pluck("users.id")

      # Get mentors of mentees
      mentor_user_ids = Mentee.where(id: mentee_ids)
                              .where.not(mentor_id: nil)
                              .joins(mentor: :user)
                              .pluck("users.id")

      (mentee_user_ids + mentor_user_ids).include?(recipient.id)
    else
      false
    end
  end

  # Get list of users this user can message
  def messageable_users
    return User.none unless @user

    case @role
    when :admin, :staff
      User.where.not(id: @user.id)
    when :mentor
      mentee_ids = @user.mentor&.mentees&.pluck(:id) || []
      mentee_user_ids = Mentee.where(id: mentee_ids).joins(:user).pluck("users.id")
      guardian_user_ids = FamilyMember.joins(:mentee, guardian: :user)
                                       .where(mentee_id: mentee_ids)
                                       .pluck("users.id")
      User.where(id: mentee_user_ids + guardian_user_ids)
    when :mentee
      mentor_user_id = @user.mentee&.mentor&.user&.id
      guardian_user_ids = @user.mentee&.family_members&.joins(guardian: :user)&.pluck("users.id") || []
      User.where(id: ([mentor_user_id] + guardian_user_ids).compact)
    when :guardian
      mentee_ids = @user.guardian&.family_members&.pluck(:mentee_id) || []
      mentee_user_ids = Mentee.where(id: mentee_ids).joins(:user).pluck("users.id")
      mentor_user_ids = Mentee.where(id: mentee_ids)
                              .where.not(mentor_id: nil)
                              .joins(mentor: :user)
                              .pluck("users.id")
      User.where(id: mentee_user_ids + mentor_user_ids)
    else
      User.none
    end
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

    def can_message?(user, recipient, in_thread_with: nil)
      new(user).can_message?(recipient, in_thread_with: in_thread_with)
    end

    def messageable_users(user)
      new(user).messageable_users
    end

    # Returns users who have a specific permission
    def users_with_permission(action, resource)
      roles_with_permission = PERMISSIONS.select do |_role, permissions|
        permissions[resource]&.include?(action)
      end.keys

      # Build query based on roles that have this permission
      queries = roles_with_permission.map do |role|
        case role
        when :admin
          User.joins(:staff).where(staff: { permission_level: :admin })
        when :staff
          User.joins(:staff)
        when :mentor
          User.joins(:mentor)
        when :mentee
          User.joins(:mentee)
        when :guardian
          User.joins(:guardian)
        when :volunteer
          User.joins(:volunteer)
        end
      end.compact

      return User.none if queries.empty?

      # Combine all queries with OR
      combined = queries.reduce { |result, query| result.or(query) }
      combined.distinct
    end
  end

  private

  # Get all user IDs who are participants in a message thread
  def thread_participant_ids(message)
    return [] unless message

    root = message.thread_root
    thread_messages = [root] + root.replies

    author_ids = thread_messages.map(&:author_id)
    recipient_ids = MessageRecipient.where(message_id: thread_messages.map(&:id)).pluck(:recipient_id)

    (author_ids + recipient_ids).uniq
  end

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
