defmodule MishkaAuth.Helper.SanitizeStrategy do
  import Ecto.Changeset


  # No capital letter allowed, must contain `@` and `.` and "top-level domain" must be at least 2 character.
  @spec regex_validation(:email | :password | :username) :: Regex.t()
  def regex_validation(:email) do
    ~r/[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,63}$/
  end

  # Must contain lowercase and uppercase and number, at least 8 character.
  def regex_validation(:password) do
    ~r/(?=.*\d)(?=.*[a-zA-Z])(?!.*(\s)).{8,32}$/
  end

  # No capital letter allowed, can contain `_` and `.`, can't start with number or `_` or `.`, can't end with `_` or `.`.
  def regex_validation(:username) do
    ~r/(?!(\.))(?!(\_))([a-z0-9_\.]{2,15})[a-z0-9]$/
  end

  @spec changeset_input_validation(any, :custom | :default) :: Ecto.Changeset.t()
  def changeset_input_validation(changeset, :default) do
    changeset
    |> validate_format(:email, regex_validation(:email), message: "فرمت ایمیل درست نمی باشد.")
     |> validate_format(:username, regex_validation(:username), message: "فرمت نام کاربری درست نمی باشد.")
     |> validate_format(:password, regex_validation(:password), message: "فرمت پسورد درست نمی باشد.")
  end

  def changeset_input_validation(changeset, :custom) do
    apply(MishkaAuth.get_config_info(:input_validation_module), MishkaAuth.get_config_info(:input_validation_function), [changeset])
  end
end
