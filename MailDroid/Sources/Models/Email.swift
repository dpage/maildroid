import Foundation

struct Email: Identifiable, Codable {
    let id: String
    let threadId: String
    let accountId: String
    let subject: String
    let from: String
    let to: String
    let date: Date
    let snippet: String
    let body: String
    let labels: [String]
    let isUnread: Bool

    init(
        id: String,
        threadId: String,
        accountId: String,
        subject: String = "",
        from: String = "",
        to: String = "",
        date: Date = Date(),
        snippet: String = "",
        body: String = "",
        labels: [String] = [],
        isUnread: Bool = true
    ) {
        self.id = id
        self.threadId = threadId
        self.accountId = accountId
        self.subject = subject
        self.from = from
        self.to = to
        self.date = date
        self.snippet = snippet
        self.body = body
        self.labels = labels
        self.isUnread = isUnread
    }
}
