import Foundation
import SwiftUI

struct TabCoordinatableView<T: TabCoordinatable, U: View>: View {
    private var coordinator: T
    private let router: TabRouter<T>
    @ObservedObject var child: TabChild
    private var customize: (AnyView) -> U
    private var views: [AnyView]
    
    @State
    var offset: CGFloat = 0
    
    @State
    var scrollTo: CGFloat = -1
    
    var indicatorOffset: CGFloat {
        let progress = offset / screenWidth
        let maxWidth: CGFloat = (screenWidth - 40) / 4
        let value = progress * maxWidth + 20
//        + 10
//        + (progress * 2)
        
        print("offset -> \(offset), value -> \(value)")
        return value
    }
    
    var currentIndex: Int {
        let progress = round(offset / screenWidth)
        // For Saftey...
        let index = min(Int(progress), 4 - 1)
        return index
    }
    
    var body: some View {
        customize(
            AnyView(
//                TabView(selection: $child.activeTab) {
//                    ForEach(Array(views.enumerated()), id: \.offset) { view in
//                        view
//                            .element
//                            .tabItem {
//                                coordinator.child.allItems[view.offset].tabItem(view.offset == child.activeTab)
//                            }
//                            .tag(view.offset)
//                    }
//                }
                
                ZStack(alignment: .bottom) {
                    OffsetPageTabView(offset: $offset, scrollTo: $scrollTo) {
                        ForEach(Array(views.enumerated()), id: \.offset) { view in
                            view.element.tag(view.offset)
                        }
                    }
                    .background(Color.black.edgesIgnoringSafeArea(.all))
                    .mask {
                        Rectangle()
                            .cornerRadius(20, antialiased: true)
//                            .cornerRadius([.bottomLeading, .bottomTrailing], 20)
                            .offset(y: -50)
        //                    .foregroundColor(.red)
        //                    .cornerRadius([.bottomLeft, .bottomRight], 20)
                    }
                    
                    HStack(spacing: 0) {
                        
                        ForEach(Array(views.enumerated()), id: \.offset) { view in
                            Button {
                                withAnimation(.tabSelection) {
                                    scrollTo = screenWidth * CGFloat(view.offset)
                                }
                            } label: {
                                Image(systemName: currentIndex == view.offset ? "die.face.1.fill" : "die.face.1")
                                    .frame(maxWidth: .infinity, alignment: .center)
        //                            .height(30)
                                    .background(Color.black)
                                    .padding(.vertical, 26)
                                    .foregroundColor(Color.gray)
        //                            .background(Color.green)
                            }.contextMenu(menuItems: {
                                Text("Action 1")
                                Text("Action 2")
                            })
                        }
                    }
                    .overlay(
                        Rectangle()
                            .frame(width: 28, height: 4)
                            .cornerRadius(3)
        //                    .frame(width: 88)
                        
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .offset(x: indicatorOffset)
        //                    .foregroundColor(color)
        //                    .blendMode(.)
                    )
                    .padding(.horizontal, 20)
                    .frame(width: screenWidth, height: 30, alignment: .center)
                    .background()
                }
                    .background(Color.black)
                
            )
        )
        .environmentObject(router)
        
    }
    
    init(paths: [AnyKeyPath], coordinator: T, customize: @escaping (AnyView) -> U) {
        self.coordinator = coordinator
        
        self.router = TabRouter(coordinator: coordinator.routerStorable)
        RouterStore.shared.store(router: router)
        self.customize = customize
        self.child = coordinator.child
        
        if coordinator.child.allItems == nil {
            coordinator.setupAllTabs()
        }

        self.views = coordinator.child.allItems.map {
            $0.presentable.view()
        }
    }
}


extension Animation {
    static let openCard = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let closeCard = Animation.spring(response: 0.6, dampingFraction: 0.9)
    static let flipCard = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let tabSelection = Animation.spring(response: 0.3, dampingFraction: 0.7)
}

extension View {
    var screenBounds: CGRect {
        UIScreen.main.bounds
    }

    var screenWidth: CGFloat {
        screenBounds.width
    }

    var screenHeight: CGFloat {
        screenBounds.height
    }
}


struct OffsetPageTabView<Content: View>: UIViewRepresentable {
    var content: Content
    
    @Binding
    var offset: CGFloat

    @Binding var scrollTo: CGFloat
    
    func makeCoordinator() -> Coordinator {
        OffsetPageTabView.Coordinator(parent: self)
    }
    
    init(offset: Binding<CGFloat>,
         scrollTo:  Binding<CGFloat>,
         @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        _offset = offset
        _scrollTo = scrollTo
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollview = UIScrollView()

        // Extracting SwiftUI View and embedding into UIKit ScrollView...
        let hostview = UIHostingController(rootView: content)
        hostview.view.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            hostview.view.topAnchor.constraint(equalTo: scrollview.topAnchor),
            hostview.view.leadingAnchor.constraint(equalTo: scrollview.leadingAnchor),
            hostview.view.trailingAnchor.constraint(equalTo: scrollview.trailingAnchor),
            hostview.view.bottomAnchor.constraint(equalTo: scrollview.bottomAnchor),

            // if you are using vertical Paging...
            // then dont declare height constraint...
            hostview.view.heightAnchor.constraint(equalTo: scrollview.heightAnchor),
        ]

        hostview.view.backgroundColor = nil

        scrollview.addSubview(hostview.view)
        scrollview.addConstraints(constraints)

        // ENabling Paging...
        scrollview.isPagingEnabled = true
        scrollview.showsVerticalScrollIndicator = false
        scrollview.showsHorizontalScrollIndicator = false
        
        scrollview.bounces = false
        scrollview.alwaysBounceHorizontal = false
        
        // setting Delegate...
        scrollview.delegate = context.coordinator

        scrollview.backgroundColor = nil

        return scrollview
    }

    func updateUIView(_ uiView: UIScrollView, context _: Context) {
        // need to update only when offset changed manually...
        // just check the current and scrollview offsets...
        let currentOffset = uiView.contentOffset.x

//        if currentOffset != offset {
//            uiView.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
//        }
        
        if (scrollTo != -1) {
            uiView.setContentOffset(CGPoint(x: scrollTo, y: 0), animated: true)
        }
    }

    // Pager Offset...
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: OffsetPageTabView

        init(parent: OffsetPageTabView) {
            self.parent = parent
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let offset = scrollView.contentOffset.x
            parent.offset = offset
        }
        
        func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
            parent.scrollTo = -1
        }
    }
}
