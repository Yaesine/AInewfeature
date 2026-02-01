import Foundation

struct OpenAIClient {
    struct RequestBody: Encodable {
        struct Message: Encodable {
            let role: String
            let content: String
        }

        let model: String
        let messages: [Message]
        let temperature: Double
    }

    struct ResponseBody: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String?
            }

            let message: Message
        }

        let choices: [Choice]
    }

    func runInstruction(input: String, instruction: String, model: String, apiKey: String, temperature: Double) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw WorkflowError.invalidURL
        }

        let systemMessage = "You are a helpful assistant. Follow the user instruction precisely. Output plain text only. Keep the response concise."
        let userMessage = "Instruction: \(instruction)\n\nInput:\n\(input)"

        let body = RequestBody(
            model: model,
            messages: [
                .init(role: "system", content: systemMessage),
                .init(role: "user", content: userMessage)
            ],
            temperature: temperature
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WorkflowError.apiError("Request failed (\(httpResponse.statusCode)). \(errorText)")
        }

        let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
        guard let content = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw WorkflowError.emptyResponse
        }
        return content
    }
}
