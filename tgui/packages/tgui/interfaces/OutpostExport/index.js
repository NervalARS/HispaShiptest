import { createSearch, decodeHtmlEntities } from 'common/string';
import { useBackend, useLocalState } from '../../backend';
import {
  Box,
  Button,
  Input,
  Section,
  Table,
  NoticeBox,
} from '../../components';
import { Window } from '../../layouts';
import { formatMoney } from '../../format';

const MAX_SEARCH_RESULTS = 25;

// this UI is heavily based on (read: basically copy-pasted from) Uplink.js.

export const OutpostExport = (props, context) => {
  const { data } = useBackend(context);
  const { telecrystals } = data;
  return (
    <Window width={620} height={580} theme="ntos_terminal" resizable>
      <Window.Content scrollable>
        <GenericExport />
      </Window.Content>
    </Window>
  );
};

// expected data structure:
// redeemExports = array of export items
// allExports = array of export items
//
// "export item" = {
//   type = string
//   name = string
//   value = number
//   desc = string
//   exportAtoms = array of keys representing distinct atoms on the export pad
// }
//
//

const GenericExport = (props, context) => {
  const { act, data } = useBackend(context);
  const { redeemExports = [], allExports = [] } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [compactMode, setCompactMode] = useLocalState(
    context,
    'compactMode',
    false
  );
  const testSearch = createSearch(searchText, (item) => {
    return item.name + item.desc;
  });
  return (
    <>
      <Section
        title={
          <Box inline color={'good'}>
            Redeemable Bounties
          </Box>
        }
      >
        <ExportList compactMode={false} exportList={redeemExports} redeemable />
      </Section>
      <Section
        title={
          <Box inline color={'good'}>
            All Bounties
          </Box>
        }
        buttons={
          <>
            Search
            <Input
              value={searchText}
              onInput={(e, value) => setSearchText(value)}
              mx={1}
            />
            <Button
              icon={'sync'}
              tooltip={'Refresh'}
              onClick={() => act('recalc')}
            />
            <Button
              icon={compactMode ? 'list' : 'info'}
              content={compactMode ? 'Compact' : 'Detailed'}
              onClick={() => setCompactMode(!compactMode)}
            />
          </>
        }
      >
        {allExports.length === 0 && (
          <NoticeBox>
            {searchText.length === 0
              ? 'No bounties are available.'
              : 'No results found.'}
          </NoticeBox>
        )}
        <ExportList
          compactMode={searchText.length > 0 || compactMode}
          exportList={allExports}
        />
      </Section>
    </>
  );
};

const ExportList = (props, context) => {
  const { compactMode, exportList = [], redeemable = false } = props;
  const { act } = useBackend(context);
  const [hoveredItem, setHoveredItem] = useLocalState(
    context,
    'hoveredItem',
    {}
  );

  // append some extra data depending on whether we're in redeemable mode
  const items = exportList.map((item) => {
    let disabled = false;
    if (redeemable) {
      const notSameItem = hoveredItem && hoveredItem.name !== item.name;
      let foundOverlap = false;
      item.exportAtoms.forEach((element) => {
        if (
          hoveredItem &&
          hoveredItem.exportAtoms &&
          hoveredItem.exportAtoms.includes(element)
        ) {
          foundOverlap = true;
        }
      });
      disabled = notSameItem && foundOverlap;
    } else {
      disabled = true;
    }
    return {
      ...item,
      disabled,
    };
  });

  if (compactMode) {
    return (
      <Table>
        {items.map((item) => (
          <Table.Row key={item.name} className="candystripe">
            <Table.Cell bold>{decodeHtmlEntities(item.name)}</Table.Cell>
            <Table.Cell collapsing textAlign="right">
              <Button
                fluid
                content={formatMoney(item.value) + ' cr'}
                disabled={item.disabled}
                tooltip={item.desc}
                tooltipPosition="left"
                onmouseover={() => setHoveredItem(item)}
                onmouseout={() => setHoveredItem({})}
                onClick={() =>
                  act('redeem', {
                    redeem_type: item.type,
                  })
                }
              />
            </Table.Cell>
          </Table.Row>
        ))}
      </Table>
    );
  }

  // ! need to add the things currently associated with the bounty
  return items.map((item) => (
    <Section
      key={item.name}
      title={item.name}
      level={2}
      buttons={
        <Button
          content={formatMoney(item.value) + ' cr'}
          disabled={item.disabled}
          onmouseover={() => setHoveredItem(item)}
          onmouseout={() => setHoveredItem({})}
          onClick={() =>
            act('redeem', {
              redeem_type: item.type,
            })
          }
        />
      }
    >
      {decodeHtmlEntities(item.desc)}
    </Section>
  ));
};
