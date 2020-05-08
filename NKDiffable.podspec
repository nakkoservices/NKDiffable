Pod::Spec.new do |s|
    s.name = 'NKDiffable'
    s.version = '2.0.3'
    s.license = 'MIT'
    s.summary = 'Replacement classes for UITableViewDiffableDataSource and UICollectionViewDiffableDataSource for iOS 12 and lower.'
    s.description  = 'Replacement classes for UITableViewDiffableDataSource and UICollectionViewDiffableDataSource for iOS 12 and lower. On iOS 13+ it uses Apple\'s own implementation.'
    s.homepage = 'https://github.com/nakkoservices/NKDiffable'
    s.social_media_url = 'https://twitter.com/nakko'
    s.authors = { 'Mihai Fratu' => 'zeusent@msn.com' }
    s.source = { :git => 'https://github.com/nakkoservices/NKDiffable.git', :tag => s.version }
    
    s.ios.deployment_target = '11.0'
    s.swift_versions = '5.1'
    
    s.source_files = 'Sources/NKDiffable/**/*.swift'
    
    s.requires_arc = true
end
