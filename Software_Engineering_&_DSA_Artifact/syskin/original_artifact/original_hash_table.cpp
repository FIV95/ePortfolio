// CS300 Project Two - Advising Assistant (Hash Table, Separate Chaining)
// Author: Frank Lawrence
// Notes:
//  - Input CSV columns: courseNumber, courseTitle, prereq1, prereq2, ...
//  - Menu options: 1) Load, 2) Print all (alphanumeric), 3) Print one, 9) Exit
//  - Hash table chosen per Project One recommendation
//  - Numeric-aware sort: compares prefix letters, then numeric part (CS9 < CS10)

#include <algorithm>
#include <cctype>
#include <exception>
#include <fstream>
#include <iostream>
#include <list>
#include <sstream>
#include <string>
#include <unordered_set>
#include <utility>
#include <vector>

using std::cin;
using std::cout;
using std::list;
using std::size_t;
using std::string;
using std::vector;

// ------------------------------ Utilities ------------------------------

static inline string trim(const string& s) {
    size_t b = 0, e = s.size();

    while (b < e && std::isspace(static_cast<unsigned char>(s[b]))) {
        ++b;
    }

    while (e > b && std::isspace(static_cast<unsigned char>(s[e - 1]))) {
        --e;
    }

    return s.substr(b, e - b);
}

static inline string upper(string s) {
    for (auto& ch : s) {
        ch = static_cast<char>(std::toupper(static_cast<unsigned char>(ch)));
    }

    return s;
}

static vector<string> splitCSV(const string& line) {
    // Assumes simple CSV with no quoted commas.
    vector<string> out;
    std::stringstream ss(line);
    string cell;

    while (std::getline(ss, cell, ',')) {
        out.push_back(trim(cell));
    }

    // Keep empty trailing fields if any.
    if (!line.empty() && line.back() == ',') {
        out.push_back("");
    }

    return out;
}

struct CodeParts {
    string prefix;
    int number;
};

// Split "CSCI200" -> ("CSCI", 200); "MATH201" -> ("MATH", 201)
static CodeParts splitPrefixNumber(const string& codeUC) {
    CodeParts r;
    r.number = 0;

    size_t i = 0;

    while (i < codeUC.size() && std::isalpha(static_cast<unsigned char>(codeUC[i]))) {
        ++i;
    }

    r.prefix = codeUC.substr(0, i);

    if (i < codeUC.size()) {
        try {
            r.number = std::stoi(codeUC.substr(i));
        } catch (...) {
            r.number = 0;
        }
    }

    return r;
}

static bool codeLessNumericAware(const string& a, const string& b) {
    CodeParts A = splitPrefixNumber(a);
    CodeParts B = splitPrefixNumber(b);

    if (A.prefix != B.prefix) {
        return A.prefix < B.prefix;
    }

    return A.number < B.number;
}

// ------------------------------ Domain ------------------------------

struct Course {
    string code;              // UPPERCASE course number, such as CSCI200
    string title;             // Course title
    vector<string> prereqs;   // UPPERCASE codes of prerequisites
};

// ------------------------------ Hash Table ------------------------------

class HashTable {
public:
    explicit HashTable(size_t tableSize = 179) : buckets_(tableSize) {}

    void clear() {
        for (auto& bucket : buckets_) {
            bucket.clear();
        }

        size_ = 0;
    }

    bool insertOrAssign(const Course& c) {
        size_t idx = hashKey(c.code);

        // Replace if the course already exists.
        for (auto& node : buckets_[idx]) {
            if (node.key == c.code) {
                node.value = c;
                return false;
            }
        }

        buckets_[idx].push_front({c.code, c});
        ++size_;
        return true;
    }

    const Course* find(const string& code) const {
        size_t idx = hashKey(code);

        for (const auto& node : buckets_[idx]) {
            if (node.key == code) {
                return &node.value;
            }
        }

        return nullptr;
    }

    vector<Course> toVector() const {
        vector<Course> v;
        v.reserve(size_);

        for (const auto& bucket : buckets_) {
            for (const auto& node : bucket) {
                v.push_back(node.value);
            }
        }

        return v;
    }

    bool empty() const {
        return size_ == 0;
    }

private:
    struct Node {
        string key;
        Course value;
    };

    vector<list<Node>> buckets_;
    size_t size_ = 0;

    size_t hashKey(const string& key) const {
        // Simple sum-of-characters hash.
        unsigned long sum = 0;

        for (unsigned char ch : key) {
            sum += ch;
        }

        return sum % buckets_.size();
    }
};

// ------------------------------ Loader ------------------------------

static vector<string> readAllNonEmptyLines(const string& path) {
    std::ifstream file(path);

    if (!file) {
        throw std::runtime_error("Error: couldn't open file: " + path);
    }

    vector<string> lines;
    string line;

    while (std::getline(file, line)) {
        line = trim(line);

        if (!line.empty()) {
            lines.push_back(line);
        }
    }

    if (lines.empty()) {
        throw std::runtime_error("Error: file has no data.");
    }

    return lines;
}

// Validates and loads courses into the hash table.
// This replaces existing table contents.
static size_t loadCoursesIntoHash(const string& path, HashTable& table) {
    auto rows = readAllNonEmptyLines(path);

    vector<Course> temp;
    temp.reserve(rows.size());

    std::unordered_set<string> codesSet;
    codesSet.reserve(rows.size() * 2);

    // Pass 1: parse rows, gather codes, and perform basic checks.
    size_t lineNo = 0;

    for (const auto& row : rows) {
        ++lineNo;

        auto cols = splitCSV(row);

        if (cols.size() < 2) {
            throw std::runtime_error(
                "Format error on line " + std::to_string(lineNo) +
                ": need courseNumber and title."
            );
        }

        string code = upper(trim(cols[0]));
        string title = trim(cols[1]);

        if (code.empty() || title.empty()) {
            throw std::runtime_error(
                "Format error on line " + std::to_string(lineNo) +
                ": missing courseNumber or title."
            );
        }

        Course c;
        c.code = code;
        c.title = title;

        // Collect and de-duplicate prerequisites from the same row.
        std::unordered_set<string> seenRowPrereqs;

        for (size_t i = 2; i < cols.size(); ++i) {
            string p = upper(trim(cols[i]));

            if (!p.empty() && !seenRowPrereqs.count(p)) {
                if (p == code) {
                    throw std::runtime_error(
                        "Format error on line " + std::to_string(lineNo) +
                        ": self prerequisite listed for " + code + "."
                    );
                }

                c.prereqs.push_back(p);
                seenRowPrereqs.insert(p);
            }
        }

        if (codesSet.count(code)) {
            throw std::runtime_error("Format error: duplicate course " + code + ".");
        }

        codesSet.insert(code);
        temp.push_back(std::move(c));
    }

    // Pass 2: every prerequisite must exist in the file.
    for (const auto& c : temp) {
        for (const auto& p : c.prereqs) {
            if (!codesSet.count(p)) {
                throw std::runtime_error(
                    "Format error: course " + c.code +
                    " lists missing prerequisite " + p + "."
                );
            }
        }
    }

    // Commit after validation succeeds.
    table.clear();

    for (const auto& c : temp) {
        table.insertOrAssign(c);
    }

    return temp.size();
}

// ------------------------------ Printing ------------------------------

// Option 2: print alphanumeric list of courses only.
static void printAllSorted(const HashTable& table) {
    auto all = table.toVector();

    std::sort(
        all.begin(),
        all.end(),
        [](const Course& a, const Course& b) {
            return codeLessNumericAware(a.code, b.code);
        }
    );

    cout << "\nComputer Science Course List (Alphanumeric Order)\n";
    cout << "--------------------------------------------------\n";

    for (const auto& c : all) {
        cout << c.code << " - " << c.title << "\n";
    }
}

// Option 3: print one course with prerequisite numbers and titles.
static void printOneCourse(const HashTable& table, const string& rawInput) {
    string q = upper(trim(rawInput));

    if (q.empty()) {
        cout << "Invalid input.\n";
        return;
    }

    const Course* c = table.find(q);

    if (!c) {
        cout << "Course not found.\n";
        return;
    }

    cout << c->code << " - " << c->title << "\n";

    if (c->prereqs.empty()) {
        cout << "Prerequisites: None\n";
        return;
    }

    cout << "Prerequisites:\n";

    for (const auto& pcode : c->prereqs) {
        const Course* pc = table.find(pcode);

        if (pc) {
            cout << "  " << pc->code << " - " << pc->title << "\n";
        } else {
            // Should not happen because prerequisites are validated during load.
            cout << "  " << pcode << " - (title unavailable)\n";
        }
    }
}

// ------------------------------ Menu ------------------------------

static void printMenu() {
    cout << "\n1) Load file\n"
            "2) Print all (sorted)\n"
            "3) Print one course\n"
            "9) Exit\n"
            "Choice: ";
}

int main() {
    std::ios::sync_with_stdio(false);
    cin.tie(nullptr);

    HashTable table;
    bool running = true;

    while (running) {
        printMenu();

        string choiceStr;

        if (!std::getline(cin, choiceStr)) {
            break;
        }

        choiceStr = trim(choiceStr);

        if (choiceStr.empty()) {
            continue;
        }

        int choice = -1;

        try {
            choice = std::stoi(choiceStr);
        } catch (...) {
            choice = -1;
        }

        switch (choice) {
            case 1: {
                cout << "Enter CSV path: ";

                string path;

                if (!std::getline(cin, path)) {
                    cout << "Input error.\n";
                    break;
                }

                path = trim(path);

                if (path.empty()) {
                    cout << "Path cannot be empty.\n";
                    break;
                }

                try {
                    size_t loaded = loadCoursesIntoHash(path, table);
                    cout << "Loaded " << loaded << " courses into HashTable.\n";
                } catch (const std::exception& ex) {
                    cout << ex.what() << "\n";
                }

                break;
            }

            case 2: {
                if (table.empty()) {
                    cout << "No data loaded. Choose 1) Load file first.\n";
                    break;
                }

                printAllSorted(table);
                break;
            }

            case 3: {
                if (table.empty()) {
                    cout << "No data loaded. Choose 1) Load file first.\n";
                    break;
                }

                cout << "Course number? ";

                string q;

                if (!std::getline(cin, q)) {
                    cout << "Input error.\n";
                    break;
                }

                printOneCourse(table, q);
                break;
            }

            case 9:
                running = false;
                cout << "Goodbye!\n";
                break;

            default:
                cout << "Invalid choice.\n";
                break;
        }
    }

    return 0;
}
