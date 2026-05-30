export type PaginationParams = {
  page: number;
  perPage: number;
};

export type PaginatedResult<TItem> = {
  items: TItem[];
  pagination: {
    page: number;
    perPage: number;
    totalItems: number;
    totalPages: number;
  };
};

export const DEFAULT_PAGE = 1;
export const DEFAULT_PER_PAGE = 20;
export const MAX_PER_PAGE = 100;
