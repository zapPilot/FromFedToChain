1. check `/guidelines/categories/macro.md`. Each category has specific topic selection criteria and style guidelines. Also check `/content/zh-TW/macro/*.json. Be aware of the `status == 
2. Find valid candidates from `sources.md` which happens at $ARGUMENTS
3. use `zen` to find more candidates which happens at $ARGUMENTS
4. Write conversational Traditional Chinese explainer in 得到/樊登讀書會 style
5. Content Format: Content follows the structured JSON schema defined in `schema.json`. See the schema file for complete format specification and validation rules.
6. Saves to `/content/zh-TW/macro/$ARGUMENTS-topic-name.json`
7. Sets `source_reviewed: false` for human review