import SwiftUI

struct ImageViewer: View {
    let imageURLs: [String]
    let initialIndex: Int
    @Binding var isPresented: Bool
    
    @State private var currentIndex: Int
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    init(imageURLs: [String], initialIndex: Int, isPresented: Binding<Bool>) {
        self.imageURLs = imageURLs
        self.initialIndex = initialIndex
        self._isPresented = isPresented
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    var body: some View {
        ZStack {
            backgroundView
            
            VStack {
                topBar
                Spacer()
                imageTabView
                Spacer()
                pageIndicators
            }
        }
        .statusBarHidden()
        .transition(.opacity)
    }
    
    private var backgroundView: some View {
        Color.black
            .ignoresSafeArea()
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
    }
    
    private var topBar: some View {
        HStack {
            Button("Done") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isPresented = false
                }
            }
            .foregroundColor(.white)
            .padding()
            
            Spacer()
            
            if imageURLs.count > 1 {
                Text("\(currentIndex + 1) of \(imageURLs.count)")
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
    
    private var imageTabView: some View {
        TabView(selection: $currentIndex) {
            ForEach(imageURLs.indices, id: \.self) { index in
                imageContainer(at: index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .gesture(swipeGesture)
    }
    
    private func imageContainer(at index: Int) -> some View {
        GeometryReader { geometry in
            imageView(at: index, geometry: geometry)
        }
        .tag(index)
        .onChange(of: currentIndex) {
            resetZoom()
        }
    }
    
    private func imageView(at index: Int, geometry: GeometryProxy) -> some View {
        AsyncImage(url: URL(string: imageURLs[index])) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaleEffect(scale)
                .offset(offset)
                .position(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                )
                .gesture(imageGestures(geometry: geometry))
                .onTapGesture(count: 2) {
                    doubleTapZoom()
                }
        } placeholder: {
            imagePlaceholder(geometry: geometry)
        }
    }
    
    private func imagePlaceholder(geometry: GeometryProxy) -> some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
    }
    
    private func imageGestures(geometry: GeometryProxy) -> some Gesture {
        SimultaneousGesture(
            magnificationGesture,
            dragGesture(geometry: geometry)
        )
    }
    
    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let delta = value / lastScale
                lastScale = value
                scale *= delta
                scale = min(max(scale, 1.0), 4.0)
            }
            .onEnded { _ in
                lastScale = 1.0
                if scale < 1.0 {
                    withAnimation(.spring()) {
                        scale = 1.0
                        offset = .zero
                    }
                }
            }
    }
    
    private func dragGesture(geometry: GeometryProxy) -> some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1.0 {
                    let newOffset = CGSize(
                        width: lastOffset.width + value.translation.width,
                        height: lastOffset.height + value.translation.height
                    )
                    
                    let maxOffsetX = (geometry.size.width * (scale - 1)) / 2
                    let maxOffsetY = (geometry.size.height * (scale - 1)) / 2
                    
                    offset = CGSize(
                        width: min(max(newOffset.width, -maxOffsetX), maxOffsetX),
                        height: min(max(newOffset.height, -maxOffsetY), maxOffsetY)
                    )
                }
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }
    
    private var swipeGesture: some Gesture {
        DragGesture()
            .onEnded { value in
                let threshold: CGFloat = 50
                if scale <= 1.0 {
                    if value.translation.width > threshold && currentIndex > 0 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex -= 1
                        }
                    } else if value.translation.width < -threshold && currentIndex < imageURLs.count - 1 {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentIndex += 1
                        }
                    }
                }
            }
    }
    
    private var pageIndicators: some View {
        Group {
            if imageURLs.count > 1 {
                HStack(spacing: 8) {
                    ForEach(imageURLs.indices, id: \.self) { index in
                        pageIndicator(for: index)
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func pageIndicator(for index: Int) -> some View {
        Circle()
            .fill(currentIndex == index ? Color.white : Color.white.opacity(0.5))
            .frame(width: 8, height: 8)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentIndex = index
                }
            }
    }
    
    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            scale = 1.0
            offset = .zero
            lastOffset = .zero
        }
    }
    
    private func doubleTapZoom() {
        withAnimation(.spring()) {
            if scale > 1.0 {
                scale = 1.0
                offset = .zero
                lastOffset = .zero
            } else {
                scale = 2.0
            }
        }
    }
}

#Preview {
    ImageViewer(
        imageURLs: [
            "https://images.unsplash.com/photo-1554118811-1e0d58224f24",
            "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085"
        ],
        initialIndex: 0,
        isPresented: .constant(true)
    )
} 