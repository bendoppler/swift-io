FROM swift:5.6

WORKDIR /app

COPY Package.swift ./
RUN swift package resolve

COPY Sources ./Sources
RUN swift build
CMD ./.build/debug/server-side-swift