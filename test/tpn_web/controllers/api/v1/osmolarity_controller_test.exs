defmodule TpnWeb.Api.V1.OsmolarityControllerTest do
  use TpnWeb.ConnCase, async: true

  alias Tpn.Lab.Osmolarity
  alias Tpn.Repo

  describe "GET /api/v1/osmolarity/limit" do
    setup do
      # Create test data
      patient_type = insert_patient_type(%{name: "Adult"})
      vascular_access = insert_vascular_access(%{name: "Peripheral"})

      osmolarity_limit =
        insert_osmolarity(%{
          osmolarity: Decimal.new(900),
          alert_type: "Soft",
          patient_type_id: patient_type.id,
          vascular_access_id: vascular_access.id
        })

      %{
        patient_type: patient_type,
        vascular_access: vascular_access,
        osmolarity_limit: osmolarity_limit
      }
    end

    test "returns osmolarity limit when found", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access,
      osmolarity_limit: osmolarity_limit
    } do
      conn =
        get(
          conn,
          "/api/v1/osmolarity/limit?patient_type_id=#{patient_type.id}&vascular_access_id=#{vascular_access.id}"
        )

      assert json_response(conn, 200) == %{
               "success" => true,
               "data" => %{
                 "id" => osmolarity_limit.id,
                 "osmolarity" => "900",
                 "alert_type" => "Soft",
                 "patient_type_id" => patient_type.id,
                 "vascular_access_id" => vascular_access.id
               },
               "message" => "Osmolarity limit found"
             }
    end

    test "returns error when limit not found", %{conn: conn} do
      conn = get(conn, "/api/v1/osmolarity/limit?patient_type_id=999&vascular_access_id=999")

      assert json_response(conn, 404) == %{
               "success" => false,
               "data" => nil,
               "message" => "Osmolarity limit not found for this patient type and vascular access"
             }
    end

    test "returns error when patient_type_id is missing", %{
      conn: conn,
      vascular_access: vascular_access
    } do
      conn = get(conn, "/api/v1/osmolarity/limit?vascular_access_id=#{vascular_access.id}")

      assert json_response(conn, 400) == %{
               "success" => false,
               "data" => nil,
               "message" => "Missing required parameters: patient_type_id and vascular_access_id"
             }
    end

    test "returns error when vascular_access_id is missing", %{
      conn: conn,
      patient_type: patient_type
    } do
      conn = get(conn, "/api/v1/osmolarity/limit?patient_type_id=#{patient_type.id}")

      assert json_response(conn, 400) == %{
               "success" => false,
               "data" => nil,
               "message" => "Missing required parameters: patient_type_id and vascular_access_id"
             }
    end

    test "returns error when multiple limits exist", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      # Insert duplicate osmolarity limit
      insert_osmolarity(%{
        osmolarity: Decimal.new(1200),
        alert_type: "Hard",
        patient_type_id: patient_type.id,
        vascular_access_id: vascular_access.id
      })

      conn =
        get(
          conn,
          "/api/v1/osmolarity/limit?patient_type_id=#{patient_type.id}&vascular_access_id=#{vascular_access.id}"
        )

      assert json_response(conn, 422) == %{
               "success" => false,
               "data" => nil,
               "message" =>
                 "Multiple osmolarity limits found. Please contact administrator to fix data."
             }
    end

    test "handles hard alert type", %{conn: conn} do
      patient_type = insert_patient_type(%{name: "Pediatric"})
      vascular_access = insert_vascular_access(%{name: "Central"})

      osmolarity_limit =
        insert_osmolarity(%{
          osmolarity: Decimal.new(1200),
          alert_type: "Hard",
          patient_type_id: patient_type.id,
          vascular_access_id: vascular_access.id
        })

      conn =
        get(
          conn,
          "/api/v1/osmolarity/limit?patient_type_id=#{patient_type.id}&vascular_access_id=#{vascular_access.id}"
        )

      response = json_response(conn, 200)
      assert response["data"]["alert_type"] == "Hard"
      assert response["data"]["osmolarity"] == "1200"
    end
  end

  describe "POST /api/v1/osmolarity/validate" do
    setup do
      patient_type = insert_patient_type(%{name: "Adult"})
      vascular_access = insert_vascular_access(%{name: "Peripheral"})

      osmolarity_limit =
        insert_osmolarity(%{
          osmolarity: Decimal.new(900),
          alert_type: "Soft",
          patient_type_id: patient_type.id,
          vascular_access_id: vascular_access.id
        })

      %{
        patient_type: patient_type,
        vascular_access: vascular_access,
        osmolarity_limit: osmolarity_limit
      }
    end

    test "validates osmolarity within limit", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "calculated_osmolarity" => "800",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => false
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["data"]["validation"]["exceeds"] == false
      assert response["data"]["validation"]["calculated"] == 800.0
      assert response["data"]["validation"]["limit"] == 900.0
      assert response["data"]["can_proceed"]["can_proceed"] == true
      assert response["data"]["can_proceed"]["type"] == "info"
    end

    test "validates osmolarity exceeding soft limit without comments", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "calculated_osmolarity" => "1000",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => false
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["success"] == true
      assert response["data"]["validation"]["exceeds"] == true
      assert response["data"]["validation"]["calculated"] == 1000.0
      assert response["data"]["validation"]["exceeds_limit"] == 100.0
      assert response["data"]["can_proceed"]["can_proceed"] == false
      assert response["data"]["can_proceed"]["type"] == "warning"

      assert response["data"]["can_proceed"]["message"] ==
               "Osmolarity exceeds soft limit. Please provide comments to proceed."
    end

    test "validates osmolarity exceeding soft limit with comments", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "calculated_osmolarity" => "1000",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => true
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["data"]["validation"]["exceeds"] == true
      assert response["data"]["can_proceed"]["can_proceed"] == true
      assert response["data"]["can_proceed"]["type"] == "warning"

      assert response["data"]["can_proceed"]["message"] ==
               "Osmolarity exceeds soft limit but order can proceed with comments."
    end

    test "validates osmolarity exceeding hard limit", %{conn: conn} do
      patient_type = insert_patient_type(%{name: "Neonatal"})
      vascular_access = insert_vascular_access(%{name: "PICC"})

      insert_osmolarity(%{
        osmolarity: Decimal.new(600),
        alert_type: "Hard",
        patient_type_id: patient_type.id,
        vascular_access_id: vascular_access.id
      })

      params = %{
        "calculated_osmolarity" => "800",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => true
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["data"]["validation"]["exceeds"] == true
      assert response["data"]["validation"]["alert_type"] == "Hard"
      assert response["data"]["can_proceed"]["can_proceed"] == false
      assert response["data"]["can_proceed"]["type"] == "error"

      assert response["data"]["can_proceed"]["message"] ==
               "Osmolarity exceeds hard limit. Order cannot proceed even with comments."
    end

    test "returns error when calculated_osmolarity is missing", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      assert json_response(conn, 400) == %{
               "success" => false,
               "data" => nil,
               "message" =>
                 "Missing required parameters: calculated_osmolarity, patient_type_id, and vascular_access_id"
             }
    end

    test "returns error when osmolarity limit not found", %{conn: conn} do
      params = %{
        "calculated_osmolarity" => "800",
        "patient_type_id" => 999,
        "vascular_access_id" => 999,
        "has_comments" => false
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      assert json_response(conn, 404) == %{
               "success" => false,
               "data" => nil,
               "message" => "Osmolarity limit not found for this patient type and vascular access"
             }
    end

    test "handles decimal osmolarity values", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "calculated_osmolarity" => "856.75",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => false
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["data"]["validation"]["calculated"] == 856.75
      assert response["data"]["validation"]["exceeds"] == false
    end

    test "handles string boolean for has_comments", %{
      conn: conn,
      patient_type: patient_type,
      vascular_access: vascular_access
    } do
      params = %{
        "calculated_osmolarity" => "1000",
        "patient_type_id" => patient_type.id,
        "vascular_access_id" => vascular_access.id,
        "has_comments" => "true"
      }

      conn = post(conn, "/api/v1/osmolarity/validate", params)

      response = json_response(conn, 200)
      assert response["data"]["can_proceed"]["can_proceed"] == true
    end
  end

  # Helper functions for test data creation
  defp insert_patient_type(attrs) do
    %Tpn.Lab.PatientType{}
    |> Tpn.Lab.PatientType.changeset(Map.put(attrs, :user_id, 1))
    |> Repo.insert!()
  end

  defp insert_vascular_access(attrs) do
    %Tpn.Lab.VascularAccess{}
    |> Tpn.Lab.VascularAccess.changeset(Map.put(attrs, :user_id, 1))
    |> Repo.insert!()
  end

  defp insert_osmolarity(attrs) do
    %Osmolarity{}
    |> Osmolarity.changeset(Map.put(attrs, :user_id, 1))
    |> Repo.insert!()
  end
end
