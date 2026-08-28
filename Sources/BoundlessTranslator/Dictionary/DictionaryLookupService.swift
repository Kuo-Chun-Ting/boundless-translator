import CoreServices
import Foundation

protocol DictionaryLookupServicing {
    func lookUp(_ term: String) -> String?
}

struct DictionaryServicesLookupService: DictionaryLookupServicing {
    func lookUp(_ term: String) -> String? {
        let range = CFRange(location: 0, length: term.utf16.count)

        return DCSCopyTextDefinition(nil, term as CFString, range)?
            .takeRetainedValue() as String?
    }
}
