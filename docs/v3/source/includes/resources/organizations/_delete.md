### Delete an organization

```
Example Request
```

```shell
curl "https://api.example.org/v3/organizations/[guid]" \
  -X DELETE \
  -H "Authorization: bearer [token]"
```

```
Example Response
```

```http
HTTP/1.1 202 Accepted
Location: https://api.example.org/v3/jobs/[guid]
```

#### Definition
`DELETE /v3/organizations/:guid`

#### Permitted roles

Role  | Notes
--- | ---
Admin |

