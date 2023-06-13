# [0.12.0](https://github.com/HGInsights/avalanche/compare/v0.11.7...v0.12.0) (2023-06-13)


### Features

* add support for multiple sql statements in single request (#40) ([3c8830a](https://github.com/HGInsights/avalanche/commit/3c8830a6ccb8e198e90e69d82774f43399cf2220)), closes [#40](https://github.com/HGInsights/avalanche/issues/40)

## [0.11.7](https://github.com/HGInsights/avalanche/compare/v0.11.6...v0.11.7) (2023-05-08)


### Bug Fixes

* Refactor JWT -> add boundary, adjust tests and remove unnecessary deps (#39) ([4492ed5](https://github.com/HGInsights/avalanche/commit/4492ed5a693f2611edd5507f391fdaceff776f7e)), closes [#39](https://github.com/HGInsights/avalanche/issues/39)

## [0.11.6](https://github.com/HGInsights/avalanche/compare/v0.11.5...v0.11.6) (2023-03-31)


### Bug Fixes

* typespecs, replace mentat with cachex, fix flaky test, improve docs (#38) ([a04953d](https://github.com/HGInsights/avalanche/commit/a04953dca5a5641f220c7cfdf6a45d7953a455de)), closes [#38](https://github.com/HGInsights/avalanche/issues/38)

## [0.11.5](https://github.com/HGInsights/avalanche/compare/v0.11.4...v0.11.5) (2023-03-18)


### Bug Fixes

* fix integration tests when running all tests together (#37) ([8013d24](https://github.com/HGInsights/avalanche/commit/8013d24f19520d86ab284b72ca203e5d76172fb3)), closes [#37](https://github.com/HGInsights/avalanche/issues/37)

## [0.11.4](https://github.com/HGInsights/avalanche/compare/v0.11.3...v0.11.4) (2023-03-17)


### Bug Fixes

* adjust logger level (#36) ([fe059dd](https://github.com/HGInsights/avalanche/commit/fe059ddae8245590d007b7d6876bcbf368625292)), closes [#36](https://github.com/HGInsights/avalanche/issues/36)

## [0.11.3](https://github.com/HGInsights/avalanche/compare/v0.11.2...v0.11.3) (2023-03-17)


### Bug Fixes

* update deps (req 0.3.6) (#35) ([ba34af4](https://github.com/HGInsights/avalanche/commit/ba34af4c7c5682109f5902cc35aee7f435a5bfd1)), closes [#35](https://github.com/HGInsights/avalanche/issues/35)

## [0.11.2](https://github.com/HGInsights/avalanche/compare/v0.11.1...v0.11.2) (2022-12-27)


### Bug Fixes

* update to latest Req (v0.3.3) (#34) ([7802f2e](https://github.com/HGInsights/avalanche/commit/7802f2ee3246837324f6b12b22676cb12196ec42)), closes [#34](https://github.com/HGInsights/avalanche/issues/34)

## [0.11.1](https://github.com/HGInsights/avalanche/compare/v0.11.0...v0.11.1) (2022-12-21)


### Bug Fixes

* Add missing .version file so we can compile from hex (#33) ([21c4a17](https://github.com/HGInsights/avalanche/commit/21c4a17274ab17103b68dbe2514ddd7a781988a7)), closes [#33](https://github.com/HGInsights/avalanche/issues/33)

# [0.11.0](https://github.com/HGInsights/avalanche/compare/v0.10.4...v0.11.0) (2022-12-16)


* Pin Req version to 0.3.1 (#31) ([d241e88](https://github.com/HGInsights/avalanche/commit/d241e8878c84b61bc385810999496a9125ce0af5)), closes [#31](https://github.com/HGInsights/avalanche/issues/31)


### Features

* add telemetry to status calls (#32) ([f0e69f9](https://github.com/HGInsights/avalanche/commit/f0e69f9b06ef3740a30018a6dfb5b0422444c3a9)), closes [#32](https://github.com/HGInsights/avalanche/issues/32)

## [0.10.4](https://github.com/HGInsights/avalanche/compare/v0.10.3...v0.10.4) (2022-11-16)


### Bug Fixes

* handle nil encoding by raising helpful message (#30) ([404eb21](https://github.com/HGInsights/avalanche/commit/404eb2104346d8c9c38e8bde10c5459d12c71c20)), closes [#30](https://github.com/HGInsights/avalanche/issues/30)

## [0.10.3](https://github.com/HGInsights/avalanche/compare/v0.10.2...v0.10.3) (2022-11-07)


### Bug Fixes

* update deps and remove overrides (#29) ([60cf76d](https://github.com/HGInsights/avalanche/commit/60cf76d465ae294a35e7683eac99d25cc5bb5864)), closes [#29](https://github.com/HGInsights/avalanche/issues/29)

## [0.10.2](https://github.com/HGInsights/avalanche/compare/v0.10.1...v0.10.2) (2022-11-07)


### Bug Fixes

* **ci:** publish package to hex (#25) ([2b0b5e5](https://github.com/HGInsights/avalanche/commit/2b0b5e5b101e4dc4c642a7b32c4f9cb6fed0fbe2)), closes [#25](https://github.com/HGInsights/avalanche/issues/25)

## [0.10.1](https://github.com/HGInsights/avalanche/compare/v0.10.0...v0.10.1) (2022-11-04)


### Bug Fixes

* add bindings to telemetry params (#28) ([25a2126](https://github.com/HGInsights/avalanche/commit/25a2126e670ae331e24e2eeec652d3f3f1b9144e)), closes [#28](https://github.com/HGInsights/avalanche/issues/28)

# [0.10.0](https://github.com/HGInsights/avalanche/compare/v0.9.1...v0.10.0) (2022-11-03)


### Features

* add telemetry to avalanche (statement query) ([32ed1af](https://github.com/HGInsights/avalanche/commit/32ed1aff0686b2b64d5c0b865a9b1c7d6b319635))

## [0.9.1](https://github.com/HGInsights/avalanche/compare/v0.9.0...v0.9.1) (2022-10-24)


### Bug Fixes

* adjust max_retries and improve tests (#24) ([d5dc7be](https://github.com/HGInsights/avalanche/commit/d5dc7be54ed3896a35102f49de4153cb8116e943)), closes [#24](https://github.com/HGInsights/avalanche/issues/24)

# [0.9.0](https://github.com/HGInsights/avalanche/compare/v0.8.3...v0.9.0) (2022-10-21)


### Features

* adjust retry strategy (#23) ([a0e856e](https://github.com/HGInsights/avalanche/commit/a0e856e472547bb5d948fb951bb48803dd9d529a)), closes [#23](https://github.com/HGInsights/avalanche/issues/23)

## [0.8.3](https://github.com/HGInsights/avalanche/compare/v0.8.2...v0.8.3) (2022-10-14)


### Bug Fixes

* add retry for 429s (#22) ([09846e7](https://github.com/HGInsights/avalanche/commit/09846e7006a9920c272ea9211a4bf7b8ee5d7525)), closes [#22](https://github.com/HGInsights/avalanche/issues/22)

## [0.8.2](https://github.com/HGInsights/avalanche/compare/v0.8.1...v0.8.2) (2022-10-12)


### Bug Fixes

* deploy type handling and comply with credo (#21) ([5b7a67e](https://github.com/HGInsights/avalanche/commit/5b7a67eb690de8e5627526364cc01e643d831524)), closes [#21](https://github.com/HGInsights/avalanche/issues/21)


* Accounts for scale when type is fixed (#20) ([22d4267](https://github.com/HGInsights/avalanche/commit/22d42679e3288c2f6b47122e01a08117ab8cf35d)), closes [#20](https://github.com/HGInsights/avalanche/issues/20)

## [0.8.1](https://github.com/HGInsights/avalanche/compare/v0.8.0...v0.8.1) (2022-10-03)


### Bug Fixes

* set defaults for options correctly (#19) ([78f0fea](https://github.com/HGInsights/avalanche/commit/78f0fea9c3e0d64dee8108f8bd6c9da55a70b477)), closes [#19](https://github.com/HGInsights/avalanche/issues/19)

# [0.8.0](https://github.com/HGInsights/avalanche/compare/v0.7.2...v0.8.0) (2022-09-29)


* HIP-3439 Add testing notes (#16) ([9541dca](https://github.com/HGInsights/avalanche/commit/9541dcac06fd8f0ce7d9549bb0ecec754b5222ca)), closes [#16](https://github.com/HGInsights/avalanche/issues/16)


### Features

* allow downcase of column names and all Req options (#18) ([6a0f7a5](https://github.com/HGInsights/avalanche/commit/6a0f7a5d1eb0558be2f54b5e5364fb8c410634fd)), closes [#18](https://github.com/HGInsights/avalanche/issues/18) [#17](https://github.com/HGInsights/avalanche/issues/17)

## [0.7.2](https://github.com/HGInsights/avalanche/compare/v0.7.1...v0.7.2) (2022-09-12)


### Bug Fixes

* running communicates status better than pending (#15) ([50b2661](https://github.com/HGInsights/avalanche/commit/50b26618d3e97a1bdf29f7c79d9c8313308b058c)), closes [#15](https://github.com/HGInsights/avalanche/issues/15)

## [0.7.1](https://github.com/HGInsights/avalanche/compare/v0.7.0...v0.7.1) (2022-09-08)


### Bug Fixes

* add statement execution status to the result (#14) ([f54b16e](https://github.com/HGInsights/avalanche/commit/f54b16e515bc4d76d782aebf27b3f43550f3e947)), closes [#14](https://github.com/HGInsights/avalanche/issues/14)

# [0.7.0](https://github.com/HGInsights/avalanche/compare/v0.6.0...v0.7.0) (2022-08-30)


### Features

* support request_id and retry params (#13) ([5ce6a61](https://github.com/HGInsights/avalanche/commit/5ce6a616bb17a2d36effcf727aa9d4c18dfdbfc6)), closes [#13](https://github.com/HGInsights/avalanche/issues/13)

# [0.6.0](https://github.com/HGInsights/avalanche/compare/v0.5.1...v0.6.0) (2022-08-17)


### Chores

* added CODEOWNERS file ([91adf87](https://github.com/HGInsights/avalanche/commit/91adf87168ff2a77d05a41cd926618f4dde9dd0e))
* update readme and add license ([96f5695](https://github.com/HGInsights/avalanche/commit/96f569562932ba06ebaa6aaad17bfd2e4e726cba))


### Features

* support async option for statement execution and status (#12) ([8f610bf](https://github.com/HGInsights/avalanche/commit/8f610bff4717c0d04fe9637f017a13c0ed71ede4)), closes [#12](https://github.com/HGInsights/avalanche/issues/12)

## [0.5.1](https://github.com/HGInsights/avalanche/compare/v0.5.0...v0.5.1) (2022-05-27)


### Bug Fixes

* update Req to latest version (#11) ([f729627](https://github.com/HGInsights/avalanche/commit/f729627f2d0b98913bad08b0bc10f1f4911b64de)), closes [#11](https://github.com/HGInsights/avalanche/issues/11)

# [0.5.0](https://github.com/HGInsights/avalanche/compare/v0.4.1...v0.5.0) (2022-05-25)


### Chores

* **deps:** bump plug from 1.13.5 to 1.13.6 (#5) ([d3471fc](https://github.com/HGInsights/avalanche/commit/d3471fce069953a399a5aa9352a775bec0881e4e)), closes [#5](https://github.com/HGInsights/avalanche/issues/5)


### Features

* add test coverage and prepare for hex.pm publish (#10) ([590bb83](https://github.com/HGInsights/avalanche/commit/590bb83520de1bdbc300082dbf9065482bc43768)), closes [#10](https://github.com/HGInsights/avalanche/issues/10)

## [0.4.1](https://github.com/HGInsights/avalanche/compare/v0.4.0...v0.4.1) (2022-04-28)


### Bug Fixes

* user agent with version and add logging (#7) ([2fe5b57](https://github.com/HGInsights/avalanche/commit/2fe5b571d1ae6eaab012e60b500ba64fdba7e295)), closes [#7](https://github.com/HGInsights/avalanche/issues/7)

# [0.4.0](https://github.com/HGInsights/avalanche/compare/v0.3.0...v0.4.0) (2022-04-25)


### Features

* get data from all partitions and poll when data is not ready (#6) ([aa367be](https://github.com/HGInsights/avalanche/commit/aa367be9157463306e16ec6025a2ca605840937f)), closes [#6](https://github.com/HGInsights/avalanche/issues/6)

# [0.3.0](https://github.com/HGInsights/avalanche/compare/v0.2.0...v0.3.0) (2022-04-21)


### Features

* parsing body.data into list of maps with columns as keys and values as native types (#4) ([53bbd67](https://github.com/HGInsights/avalanche/commit/53bbd6739910a329a90fd7d414c35e56dc25bc46)), closes [#4](https://github.com/HGInsights/avalanche/issues/4)

# [0.2.0](https://github.com/HGInsights/avalanche/compare/v0.1.0...v0.2.0) (2022-04-19)


### Features

* added support for params to bind to SQL variables (#3) ([687492f](https://github.com/HGInsights/avalanche/commit/687492fede3fbe35721abcc9f408e35895d4cae8)), closes [#3](https://github.com/HGInsights/avalanche/issues/3)
