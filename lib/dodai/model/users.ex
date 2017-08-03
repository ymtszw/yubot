use Croma

defmodule Yubot.Dodai.Model.Users do
  @moduledoc """
  Model module generator using [Dodai Users APIs](https://github.com/access-company/Dodai-doc/blob/master/users_api.md) as backend.

  ## Usage

      defmodule YourGear.Model.SomeUser do
        use #{inspect(__MODULE__)},
          data_fields: [
            f1: Croma.String,
          ]
      end

  It is mostly similar to `SolomonAcs.Dodai.Model.Datastore`, with following differences.

  - In addition to `Data`, `Rootonly` and `Readonly` submodules will be generated
    according to `:rootonly_fields` and `:readonly_fields` options.
  - User models cannot be upserted.
  - Additional APIs will be generated:
      - `update_auth_info/4`
      - `login/3`
      - `logout/2`
      - `retrieve_self/2`
  - User collection is automatically prepared for a Dodai app. Read and write permissions have to be specified via Metadata API.
  - `data._model_module` field will be set with model module name as its value.
    This field is used for querying users belonging to the model, and is hidden for gear developers and end users.
      - Do not worry about this field when inserting/updating/listing; it is implicitly ensured on inserting/updating
        and automatically included in query when listing.
      - This field is automatically indexed by Dodai.

  ## Options for `use`

  - `:data_fields` - `list`. Optionl. Origin of `Data` type submodule.
  - `:rootonly_fields` - `list`. Optionl. Origin of `Rootonly` type submodule.
  - `:readonly_fields` - `list`. Optionl. Origin of `Readonly` type submodule.
  - `:id_pattern` - `Regex.t`. Optional. See `SolomonAcs.Dodai.Model.Datastore`.
  """

  defmodule Name do
    use Croma.SubtypeOfString, pattern: ~r/\A[ -?A-~]+\Z/
  end

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @model_str         Macro.to_string(__MODULE__)
      @gear_name         Mix.Project.config()[:app]
      @dodai_gear_module SolomonAcs.Dodai.GearModule.get!(@gear_name)
      id_pattern = opts[:id_pattern]

      defmodule Id do
        use SolomonAcs.Dodai.EntityId, pattern: id_pattern
      end

      defmodule Data do
        use Croma.Struct, recursive_new?: true, fields: Keyword.get(opts, :data_fields, [])
      end

      defmodule Rootonly do
        use Croma.Struct, recursive_new?: true, fields: Keyword.get(opts, :rootonly_fields, [])
      end

      defmodule Readonly do
        use Croma.Struct, recursive_new?: true, fields: Keyword.get(opts, :readonly_fields, [])
      end

      use Croma.Struct, fields: [
        _id:             Id,
        email:           Croma.TypeGen.nilable(SolomonLib.Email),
        name:            Croma.TypeGen.nilable(Yubot.Dodai.Model.Users.Name),
        created_at:      SolomonLib.Time,
        updated_at:      SolomonLib.Time,
        version:         Croma.NonNegInteger,
        data:            Data,
        readonly:        Readonly,
        rootonly:        Croma.TypeGen.nilable(Rootonly),
        session:         Croma.TypeGen.nilable(Yubot.Dodai.Session),
        sections:        SolomonAcs.Dodai.Sections,
        section_aliases: Croma.TypeGen.list_of(Croma.TypeGen.nilable(Croma.String)),
        role:            Dodai.Model.Role,
        rules_of_user:   Croma.TypeGen.nilable(Croma.TypeGen.list_of(Yubot.Dodai.AppUsageRuleOfUser)),
      ], accept_case: :lower_camel, recursive_new?: true

      def insert(insert_action, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.insert(__MODULE__, Id, Data, Rootonly, Readonly, @dodai_gear_module.client(), insert_action, key, group_id)
      end

      def update(update_action, id, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.update(__MODULE__, @dodai_gear_module.client(), update_action, id, key, group_id)
      end

      def delete(id, version, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.delete(@dodai_gear_module.client(), id, version, key, group_id)
      end

      def retrieve(id, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.retrieve(__MODULE__, @dodai_gear_module.client(), id, key, group_id)
      end

      def retrieve_list(list_action, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.retrieve_list(__MODULE__, @dodai_gear_module.client(), list_action, key, group_id)
      end

      def count(query, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.count(__MODULE__, @dodai_gear_module.client(), query, key, group_id)
      end

      def update_auth_info(update_auth_info_action, id, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.update_auth_info(__MODULE__, @dodai_gear_module.client(), update_auth_info_action, id, key, group_id)
      end

      def login(login_action, key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.login(__MODULE__, @dodai_gear_module.client(), login_action, key, group_id)
      end

      def logout(key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.logout(@dodai_gear_module.client(), key, group_id)
      end

      def retrieve_self(key, group_id \\ @dodai_gear_module.default_group_id()) do
        Yubot.Dodai.Model.Users.Impl.retrieve_self(__MODULE__, @dodai_gear_module.client(), key, group_id)
      end
    end
  end
end
