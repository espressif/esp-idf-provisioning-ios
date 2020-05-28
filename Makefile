documentation:
	@jazzy \
		--min-acl internal \
		--no-hide-documentation-coverage \
		--theme apple \
		--output ./docs \
		--podspec ESPProvision.podspec \
		--documentation=./*.md
	@rm -rf ./build