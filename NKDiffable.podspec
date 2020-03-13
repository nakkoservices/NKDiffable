Pod::Spec.new do |s|
    s.name = 'NKDiffable'
    s.version = '1.0.0'
    s.license = 'MIT'
    s.summary = 'Replacement classes for UITableViewDiffableDataSource and UICollectionViewDiffableDataSource for iOS 12 and lower. On iOS 13+ it uses Apple\'s own implementation.'
    s.homepage = 'https://github.com/nakkoservices/NKDiffable'
    s.social_media_url = 'https://twitter.com/nakko'
    s.authors = { 'Mihai Fratu' => 'zeusent@msn.com' }
    s.source = { :git => 'https://github.com/nakkoservices/NKDiffable.git', :tag => s.version }
    
    s.ios.deployment_target = '10.0'

    s.source_files = 'NKDiffable/**/*.swift'
    
    s.requires_arc = true
end
