kor.directive "korPagination", [
  "$location", "$routeParams",
  (l, rp) ->
    directive = {
      templateUrl: "/tpl/pagination"
      replace: true
      scope: {
        page: "=korPagination"
        total: "=korTotal"
        per_page: "=korPerPage"
        use_search: "=korUseSearch"
      }
      link: (scope, element, attrs) ->
        scope.new_page ||= 1
        # scope.new_page = if scope.use_search
        #   console.log rp.page
        #   parseInt(rp.page) || 1
        # else
        #   1
        # scope.$on '$routeUpdate', -> scope.new_page = rp.page || 1
        scope.$watch "page", -> scope.update()

        scope.update = (new_page, event) ->
          if new_page
            scope.page = new_page

          if scope.page > scope.total_pages()
            scope.page = scope.total_pages()
          if scope.page < 1
            scope.page = 1

          # l.search(page: scope.page) if scope.use_search
          event.preventDefault() if event

        scope.total_pages = -> Math.ceil(scope.total / scope.per_page)

        $(element).on "click", "input[type=number]", (event) -> $(event.target).select()

        window.s = scope
    } 
]