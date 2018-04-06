defmodule Constable.AnnouncementTest do
  use Constable.ModelCase, async: true
  alias Constable.Announcement

  describe ".create_changeset" do
    test "generates a slug from the title" do
      title = "A test announcement"
      announcement = build(:announcement)

      changeset = Announcement.create_changeset(announcement, %{title: title})

      assert Ecto.Changeset.get_change(changeset, :slug) == "a-test-announcement"
    end

    test "does not generate a slug if the title is nil" do
      announcement = build(:announcement)

      changeset = Announcement.create_changeset(announcement, %{title: nil})

      refute Ecto.Changeset.get_change(changeset, :slug)
    end

    test "inserting a announcement with a duplicate title fails" do
      user = insert(:user)
      {:ok, announcement}
        = params_for(:announcement, user_id: user.id)
        |> create_announcement

      {:error, changeset}
        = params_for(:announcement, title: announcement.title, user_id: user.id)
        |> create_announcement

      assert changeset.errors[:slug] == {"has already been taken", []}
    end

    def create_announcement(params) do
      %Announcement{}
      |> Announcement.create_changeset(params)
      |> Repo.insert()
    end
  end

  test "inserting a record sets the last_discussed_at" do
    announcement = build(:announcement) |> insert

    assert announcement.last_discussed_at
  end

  test "last_discussed_first" do
    oldest = insert(:announcement, last_discussed_at: Constable.Time.days_ago(1))
    newest = insert(:announcement, last_discussed_at: Constable.Time.now)

    announcements = Announcement.last_discussed_first |> Repo.all

    assert List.first(announcements).id == newest.id
    assert List.last(announcements).id == oldest.id
  end

  test "interests are sorted alphabetically" do
    interest_a = insert(:interest, name: "a")
    interest_b = insert(:interest, name: "b")
    insert(:announcement)
      |> tag_with_interest(interest_b)
      |> tag_with_interest(interest_a)

    announcement = Announcement.with_announcement_list_assocs
      |> Repo.one

    assert announcement.interests |> List.first == interest_a
    assert announcement.interests |> List.last  == interest_b
  end
end
