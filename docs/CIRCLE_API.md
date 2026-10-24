# Me Time Club — Circle API handoff

Prepared: 24 October 2026

Audience: backend developer

Status: proposed contract for implementation; new response endpoints are not connected in Flutter yet.

Companion specification: [CIRCLE_OPENAPI.json](CIRCLE_OPENAPI.json), importable into Swagger Editor or Postman.

## 1. Implementation scope

1. Extend the existing `GET /api/v1/circle_posts` response with a `responses` array on every post.
2. Add `POST /api/v1/circle_posts/{post_id}/responses` for preset feelings and written replies.
3. Keep the existing `POST /api/v1/circle_posts` request compatible.

Heart, Hug, and Leaf buttons have been removed. The seven feeling responses are text replies, not toggles of the old `/react` endpoint.

Currently, selecting a feeling displays `Anonymous: I understand` locally below the post and automatically closes the options. These UI previews reset on app restart/feed reload. Written sending is disabled until API integration. The backend must persist both response types and return them in the feed.

## 2. Base URL and authentication

Current configured API base: `http://139.59.23.15/api/v1`. The host is environment-specific; paths below are relative to `/api/v1`.

```http
Authorization: Bearer <access_token>
Accept: application/json
Content-Type: application/json
```

All endpoints require the existing bearer session. `Content-Type` is needed for JSON request bodies. Derive the author from the token; never accept client-supplied user IDs or author names. Missing, invalid, or expired tokens return `401`, which the app uses to open login.

## 3. Fetch posts and responses

```http
GET /circle_posts
```

No request body. Return `200 OK` with an array directly at the root, without a `data` or `posts` wrapper:

```json
[
  {
    "id": 101,
    "body": "Some days I just need a moment to breathe.",
    "anonymous": true,
    "author": "Anonymous",
    "created_at": "2026-10-24T08:00:00Z",
    "responses": [
      {
        "id": 501,
        "circle_post_id": 101,
        "body": "I understand",
        "feeling_key": "i_understand",
        "anonymous": true,
        "author": "Anonymous",
        "created_at": "2026-10-24T08:15:00Z"
      },
      {
        "id": 502,
        "circle_post_id": 101,
        "body": "I'm here",
        "feeling_key": "im_here",
        "anonymous": true,
        "author": "Anonymous",
        "created_at": "2026-10-24T08:20:00Z"
      }
    ]
  }
]
```

- Posts: newest first, then descending ID for timestamp ties.
- Responses within each post: oldest first, then ascending ID for ties.
- No posts: `[]`. No responses: `responses: []`, never `null`.
- IDs: stable JSON integers. Timestamps: ISO 8601 with timezone, preferably UTC.
- Anonymous post: `anonymous: true`, `author: "Anonymous"`. Named post: `anonymous: false`, `author` is its display name.
- Do not expose private author/profile fields for anonymous content.
- Existing extra fields, including legacy reaction counts or `topic_tag`, may remain for compatibility. The updated UI does not need them.
- Include responses in this existing feed call for the first implementation. The current Flutter client does not use a separate responses-list call or a pagination wrapper.

## 4. Create a feeling response

```http
POST /circle_posts/{post_id}/responses
```

Example path: `/circle_posts/101/responses`.

Request:

```json
{
  "circle_response": {
    "body": "I understand",
    "feeling_key": "i_understand",
    "anonymous": true
  }
}
```

New response: `201 Created`, returning the object directly:

```json
{
  "id": 501,
  "circle_post_id": 101,
  "body": "I understand",
  "feeling_key": "i_understand",
  "anonymous": true,
  "author": "Anonymous",
  "created_at": "2026-10-24T08:15:00Z"
}
```

The only supported feeling keys and their exact labels:

- `holding_you` → `Holding you`
- `i_understand` → `I understand`
- `this_feels_heavy` → `This feels heavy`
- `youre_doing_okay` → `You're doing okay`
- `im_here` → `I'm here`
- `this_will_pass` → `This will pass`
- `take_a_breath` → `Take a breath`

Behavior:

- A tap submits the preset and closes the feeling options. No text input or Send button appears in this panel.
- Show the resulting `Anonymous: <body>` line below the post, above the action buttons.
- Multiple distinct feelings from one user on the same post are allowed.
- Repeating the same feeling for the same user/post must not duplicate or remove it. Return `200 OK` with the existing response object, original ID, and timestamp. Enforce this atomically, including concurrent retries.
- Unknown keys or a body that differs from the selected key's exact label return `422`.

## 5. Create a written response

Use the same endpoint:

```http
POST /circle_posts/{post_id}/responses
```

Request:

```json
{
  "circle_response": {
    "body": "You are not alone. I'm here for you.",
    "anonymous": true
  }
}
```

An omitted or null `feeling_key` means a written reply. Text that happens to equal a preset label is still a written reply when this key is absent/null.

Success: `201 Created`:

```json
{
  "id": 503,
  "circle_post_id": 101,
  "body": "You are not alone. I'm here for you.",
  "feeling_key": null,
  "anonymous": true,
  "author": "Anonymous",
  "created_at": "2026-10-24T08:30:00Z"
}
```

Behavior:

- Respond opens the text field and Send button, without showing feeling options.
- Send is disabled for blank text and pending requests; the client prevents double taps while pending.
- Clear the written draft only after success. Preserve it on failure for retry.
- Selecting a feeling must not overwrite or clear a separate written draft.
- Do not apply the preset uniqueness rule to written replies. Separate intentional written replies may have identical text.

## 6. Field definitions and validation

Response creation uses the `circle_response` wrapper:

- `body`: required string. Trim surrounding whitespace and reject blank text. Preserve Unicode, punctuation, apostrophes, and internal line breaks. Store/display plain text.
- `feeling_key`: optional string or null. A non-null value must be one of the seven keys and match its canonical body. Missing/null means written text.
- `anonymous`: optional boolean, default `true`. Replies are anonymous-only in this UI version: accept `true`; reject `false` with `422`.
- `post_id`: required positive integer in the URL. The post must exist and be accessible under the current Circle access rules.

Return these fields for every response:

- `id`: integer response ID.
- `circle_post_id`: integer parent post ID.
- `body`: string stored text.
- `feeling_key`: preset key, or null for a written reply.
- `anonymous`: `true` in this version.
- `author`: literal `Anonymous` in this version.
- `created_at`: ISO 8601 timestamp with timezone.

**Maximum written-response length is not yet specified.** Confirm the backend limit so the client can enforce the same value. No arbitrary maximum is added to this proposal. Nonblank response text is required; Gentle Reads' optional-content rules are a separate feature.

## 7. Keep existing post creation compatible

```http
POST /circle_posts
```

Existing request:

```json
{
  "circle_post": {
    "body": "Some days I just need a moment to breathe.",
    "is_anon": true
  }
}
```

Success: `201 Created`, with the post directly:

```json
{
  "id": 101,
  "body": "Some days I just need a moment to breathe.",
  "anonymous": true,
  "author": "Anonymous",
  "created_at": "2026-10-24T08:00:00Z",
  "responses": []
}
```

Post creation uses `is_anon` in the request and `anonymous` in the response, matching the existing app. The new response endpoint uses `anonymous` in both directions. Named posts remain supported with `is_anon: false`; replies are anonymous-only in this version.

## 8. Error format

Return a JSON object with a human-readable `error` string. `code` and `details` are optional; `error` must make sense by itself.

```json
{
  "error": "Response cannot be blank.",
  "code": "validation_failed",
  "details": {
    "body": ["cannot be blank"]
  }
}
```

- `400`: malformed JSON or invalid request structure.
- `401`: missing, invalid, or expired session.
- `403`: authenticated user lacks access under the existing Circle rules.
- `404`: post does not exist or is no longer available.
- `422`: invalid/blank body, unsupported feeling, mismatched label, or unsupported anonymity setting.
- `500`: unexpected failure, using a generic message.

Do not return `200` with an error object. Rejected requests must not persist a response. Return JSON rather than HTML for API errors.

## 9. Persistence requirements

- Persist each response's post reference, authenticated author reference, body, nullable feeling key, anonymity flag, and timestamps. Keep the author reference private.
- Enforce an atomic uniqueness rule for non-null feeling keys per `(post, author, feeling_key)`. A retry returns the existing row.
- Creating a response must not create a top-level post or toggle an old heart/hug/leaf reaction.
- Adding a reply must preserve earlier replies. Return both types in the feed after app restart/reload.
- Reuse existing Circle access rules; this proposal does not change the audience or membership model.

## 10. Acceptance checks

1. Empty feed returns `[]`; posts without replies include `responses: []`.
2. Each of the seven keys creates the correct Anonymous response with `201`.
3. Retrying a feeling for one user/post returns the same object with `200`, without duplication or toggle-off.
4. The same user can add a second distinct feeling; another user can independently submit the same feeling.
5. Written replies return `feeling_key: null` and preserve trimmed plain text.
6. Blank/non-string bodies, invalid keys, mismatched labels, and `anonymous: false` are rejected without saving.
7. Expired tokens return `401`; missing posts and denied access return JSON errors with appropriate status codes.
8. Reloaded feed returns both response types in chronological order with stable IDs.
9. Anonymous replies expose no private author information.
10. Existing anonymous/named post creation still works.

## 11. Handoff and Flutter integration

Please provide the deployed environment/base URL, confirm these JSON shapes, and confirm the written-response maximum.

Flutter then needs the response API method, a per-post send handler, and response IDs retained in its model. Handle `201` creation and `200` existing-preset results. Replace local previews with server responses and merge by response ID to prevent duplicate rows after a send/feed reload. Failed feelings reopen the options with retry feedback; failed written replies retain their draft. Local previews must not be treated as saved responses.
