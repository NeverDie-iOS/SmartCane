import SwiftUI
import WebKit

struct ObjectScanTestView: View {
    @StateObject private var viewModel = CaneViewModel()
    private let streamURL = "http://192.168.4.1:81/stream"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                MjpegStreamingView(urlString: streamURL)
                    .opacity(viewModel.displayImage == nil ? 1 : 0)
                
                if let image = viewModel.displayImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .edgesIgnoringSafeArea(.all)
                        .background(Color.black)
                        .transition(.opacity)
                }
                
                VStack {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(viewModel.pollingStatus.contains("🟢") ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                            .shadow(color: viewModel.pollingStatus.contains("🟢") ? .green : .clear, radius: 4)
                        
                        Text(viewModel.pollingStatus)
                            .font(.caption2)
                            .bold()
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .padding(.top, 10)
                    .shadow(radius: 5)
                    
                    Spacer()
                    
                    if !viewModel.statusMessage.isEmpty {
                        Text(viewModel.statusMessage)
                            .font(.body)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.black.opacity(0.7))
                                    .shadow(radius: 5)
                            )
                            .padding(.horizontal, 40)
                            .padding(.bottom, 10)
                            .id(viewModel.statusMessage) // 잔상 방지용 ID
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.2), value: viewModel.statusMessage)
                    }
                    
                    VStack(spacing: 20) {
                        if viewModel.isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(15)
                        }
                        
                        Button(action: {
                            Task { await viewModel.fetchPhotoFromCane() }
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title2)
                                Text("AI 수동 분석하기")
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isLoading ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(radius: 10)
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                }
                .zIndex(2)
                
                if viewModel.showFlash {
                    Color.red.opacity(0.6)
                        .edgesIgnoringSafeArea(.all)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                        .zIndex(3)
                }
                
            }
            .navigationBarHidden(true)
            .onAppear { viewModel.startPolling() }
            .onDisappear { viewModel.stopPolling() }
        }
    }
}

// 캠 모니터링 웹뷰
struct MjpegStreamingView: UIViewRepresentable {
    let urlString: String
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .black
        webView.isOpaque = false
        webView.isUserInteractionEnabled = false
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else { return }
        if webView.url != url { webView.load(URLRequest(url: url)) }
    }
}

#Preview { ObjectScanTestView() }
