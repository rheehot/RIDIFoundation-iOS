import Foundation

class _XMLParser: Operation {
    var xmlParser: Foundation.XMLParser

    public var result: Result<XMLDocument, Error>?

    private var xmlDocument: XMLDocument?
    private var xmlDocumentCurrentIndexPath = IndexPath()

    private var isNodeOpened: Bool = false

    public init(data: Data) {
        xmlParser = .init(data: data)
        super.init()

        xmlParser.delegate = self
    }

    override open func main() {
        xmlParser.parse()
    }
}

extension _XMLParser: XMLParserDelegate {
    func parserDidStartDocument(_ parser: XMLParser) {
        xmlDocument = XMLDocument()
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        result = .failure(parseError)
    }

    func parserDidEndDocument(_ parser: XMLParser) {
        result = .success(xmlDocument!)
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        let newElement = XMLElement()
        newElement.name = elementName
        newElement.attributes = attributeDict.map {
            let attribute = XMLAttribute()
            attribute.name = $0.key
            attribute.stringValue = $0.value

            return attribute
        }

        isNodeOpened = true

        guard !xmlDocumentCurrentIndexPath.isEmpty else {
            xmlDocument!.children = (xmlDocument!.children ?? []) + [newElement]
            xmlDocumentCurrentIndexPath.append(xmlDocument!.children!.endIndex - 1)
            return
        }

        xmlDocument![xmlDocumentCurrentIndexPath]!.children = (xmlDocument![xmlDocumentCurrentIndexPath]!.children ?? []) + [newElement]
        xmlDocumentCurrentIndexPath.append((xmlDocument![xmlDocumentCurrentIndexPath]?.children?.endIndex ?? 1) - 1)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        isNodeOpened = false

        var parentElementIndexPath = xmlDocumentCurrentIndexPath
        repeat {
            guard xmlDocument![xmlDocumentCurrentIndexPath]?.name == elementName else {
                parentElementIndexPath.removeLast()
                continue
            }

            xmlDocumentCurrentIndexPath.removeLast(xmlDocumentCurrentIndexPath.count - parentElementIndexPath.count + 1)
            break
        } while (!parentElementIndexPath.isEmpty)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard
            xmlDocument?[xmlDocumentCurrentIndexPath] != nil,
            isNodeOpened
        else {
            return
        }

        xmlDocument![xmlDocumentCurrentIndexPath]!.stringValue = string
    }
}
