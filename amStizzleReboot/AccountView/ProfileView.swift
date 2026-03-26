//
//  AccountView.swift
//  amStizzleReboot
//
//  Created by Fred Erik on 13.03.26.
//

import os
import PhotosUI
import Storage
import SwiftUI
import Supabase

struct ProfileView: View {
  let logger = Logger(subsystem: "amStizzleReboot", category: "ProfileView")
  @State var firstName = ""
  @State var lastName = ""
  @State var username = ""
  
  @State var isLoading = false
  
  @State var imageSelection: PhotosPickerItem?
  @State var avatarImage: AvatarImage?
  
  var body: some View {
    NavigationStack {
//        Form {
          ZStack(alignment: .bottomTrailing) {
//            Circle()
              
//            Group {
              if let avatarImage {
                avatarImage.image
                  .resizable()
                  .clipShape(Circle())
                  .frame(width: 150, height: 150)
              }
//                else {
//                Color.clear
//                  .frame(width: 80, height: 80)
//              }
//            }
//            .scaledToFit()
            
//            Spacer()
            
            PhotosPicker(selection: $imageSelection, matching: .images) {
              if let avatarImage {
                Image(systemName: "pencil.circle.fill")
                  .symbolRenderingMode(.multicolor)
                  .font(.system(size: 30))
                  .foregroundColor(.accentColor)
              } else {
                HStack {
                  Image(systemName: "pencil.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 30))
                    .foregroundColor(.accentColor)
                  Text("Add profile picture")
                }
            }
          }
        }
          
      Form {
          Section {
            TextField("First name", text: $firstName)
            TextField("Last name", text: $lastName)
            TextField("Username", text: $username)
              .textContentType(.username)
              .textInputAutocapitalization(.never)
          }
          .textContentType(.name)
          
//          Section {
//            Button("Update profile") {
//              updateProfileButtonTapped()
//            }
//            .bold()
//            
//            if isLoading {
//              ProgressView()
//            }
//          }
        }
      .padding(.top)
      .navigationTitle("Profile")
      .toolbar(content: {
        ToolbarItem(placement: .topBarLeading) {
          Button("sign out", role: .destructive) {
            Task {
              try? await Supabase.shared.auth.signOut()
            }
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button("save") {
            updateProfileButtonTapped()
          }
        }
      })
      .onChange(of: imageSelection) { _, newValue in
        guard let newValue else { return }
        loadTransferable(from: newValue)
      }
      //      }
      .task {
        await getInitialProfile()
      }
    }
  }
    func getInitialProfile() async {
      do {
        let currentUser = try await Supabase.shared.auth.session.user
        
        logger.info("Current user: \(currentUser.id)")
        
        let profile: Profile =
        try await Supabase.shared
          .from("profiles")
          .select()
          .eq("id", value: currentUser.id)
          .single()
          .execute()
          .value
        
        logger.info("\(profile.firstName!)")
        logger.info("\(profile.lastName!)")
        logger.info("\(profile.username!)")
        
        firstName = profile.firstName ?? ""
        lastName = profile.lastName ?? ""
        username = profile.username ?? ""
        
        if let avatarURL = profile.avatarURL, !avatarURL.isEmpty {
          try await downloadImage(path: avatarURL)
        }
        
      } catch {
//        debugPrint(error)

        logger.error("\(error)")
      }
    }
    
    func updateProfileButtonTapped() {
      Task {
        isLoading = true
        defer { isLoading = false }
        do {
          let imageURL = try await uploadImage()
          
          let currentUser = try await Supabase.shared.auth.session.user
          
          let updatedProfile = Profile(
            id: currentUser.id,
            firstName: firstName,
            lastName: lastName,
            username: username,
            avatarURL: imageURL,
            createdAt: Date.now,
            updatedAt: Date.now
          )
          
          try await Supabase.shared
            .from("profiles")
            .update(updatedProfile)
            .eq("id", value: currentUser.id)
            .execute()
        } catch {
          debugPrint(error)
        }
      }
    }
    private func loadTransferable(from imageSelection: PhotosPickerItem) {
      Task {
        do {
          avatarImage = try await imageSelection.loadTransferable(type: AvatarImage.self)
        } catch {
          debugPrint(error)
        }
      }
    }

    private func downloadImage(path: String) async throws {
      let data = try await Supabase.shared.storage.from("avatars").download(path: path)
      avatarImage = AvatarImage(data: data)
    }
  
    private func uploadImage() async throws -> String? {
      guard let data = avatarImage?.data else { return nil }

      let filePath = "\(UUID().uuidString).jpeg"

      try await Supabase.shared.storage
        .from("avatars")
        .upload(
          filePath,
          data: data,
          options: FileOptions(contentType: "image/jpeg")
        )
      logger.info("uploaded image to storage")
      return filePath
    }
}
#Preview {
    ProfileView()
}
