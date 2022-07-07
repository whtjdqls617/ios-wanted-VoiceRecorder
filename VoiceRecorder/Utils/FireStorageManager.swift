//
//  FireStorageManager.swift
//  VoiceRecorder
//
//  Created by 조성빈 on 2022/06/29.
//

import Foundation
import FirebaseStorage

class FireStorageManager {
    
    // MARK: - Enums
    
    enum File {
        enum Ref {
            static let recordDir: String = "recording/"
        }
        enum Path {
            static var fileName = ""
        }
        enum contentType {
            static let audio: String = ".m4a"
        }
        static var fileFullName: String {
            return ("recording\(Path.fileName)")
        }
    }
    
    // MARK: - Properties
    
    static var shared = FireStorageManager()
    
    let storage = Storage.storage()
    
    // MARK: - Methods
    
    func uploadData(_ url: URL?) {
        guard let url = url else {
            return
        }
        let storageRef = storage.reference()
        let metadata = StorageMetadata()
        metadata.contentType = "audio/x-m4a"
        let fileRef = storageRef.child("\(File.Ref.recordDir)\(File.fileFullName)")
        fileRef.putFile(from: url, metadata: metadata)
    }
    
    func fetchData(completion: @escaping ([URL]) -> Void ) {
        let storageRef = storage.reference()
        let fileRef = storageRef.child(File.Ref.recordDir)
        fileRef.listAll() { (result, error) in
            if let error = error {
                print("Error: <FireStorageManager fetchData> - \(error.localizedDescription)")
            }
            self.downloadToLocal(urls: result.items) { localUrls in
                completion(localUrls)
            }
        }
    }
    
    func downloadToLocal(urls: [StorageReference]
                         ,completion: @escaping ([URL]) -> Void
    ) {
    
        var items: [String] = []
        let stringUri: [String] = urls.map { "\($0)" }
        for uri in stringUri {
            let storageRef = self.storage.reference(forURL: uri)
            // 긴 uri 에서 "recording_2022_06_30_20:12:51" 끝 부분만 가져오기 위함
            let findIndex = uri.index(uri.endIndex, offsetBy: -29)
            let fileName = "\(uri[findIndex...]).m4a"
            guard let localPath = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            )
                .first?.appendingPathComponent(fileName) else { return }
            
            storageRef.write(toFile: localPath) { url, error in
                if let url = url {
                    items.append(url.absoluteString)
                }
                let sortedItems = items.sorted()
                let itemsToURL = sortedItems.compactMap { URL(string: $0) }
                completion(itemsToURL)
            }
        }
    }
    
    func deleteItem(_ name : String) {
        let storageRef = storage.reference()
        let fileRef = storageRef.child("\(File.Ref.recordDir)\(name)")
        fileRef.delete()
    }
}
