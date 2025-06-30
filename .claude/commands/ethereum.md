1. Check `/guidelines/categories/ethereum.md`. Each category has specific topic selection criteria and style guidelines. Also check `/content/zh-TW/ethereum/*.json`. Be aware of the `metadata.translation_status.rejection.rejected == true` when reviewing existing files. ultrathink
2. Find valid candidates from sources.md that are relevant to $ARGUMENTS. ultrathink
3. Use zen to find more candidates related to $ARGUMENTS.
4. Use `zen` to do fact-checking
5. Use claude to do fact-checking again, ultrathink
6. keep the reference urls
6. Write 3 valid candidates as conversational Traditional Chinese explainers in the style of 得到/樊登讀書會.
7. Content format: The content must follow the structured JSON schema defined in `schema.json`. Refer to the schema file for the complete format specification and validation rules.
8. Save the file to `/content/zh-TW/ethereum/$ARGUMENTS-topic-name.json`.
9. Set source_reviewed: false to indicate that human review is needed.
